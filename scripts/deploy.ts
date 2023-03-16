import { BigNumber, Signer, utils } from 'ethers'
import { GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS } from '@big-whale-labs/constants'
import { OBSSStorage__factory as LegacyOBSSStorage__factory } from '@big-whale-labs/obss-storage-contract'
import { OBSSStorage } from 'typechain'
import { Provider } from '@ethersproject/providers'
import { ethers, run, upgrades } from 'hardhat'
import { version } from '../package.json'
import prompt from 'prompt'

const regexes = {
  ethereumAddress: /^0x[a-fA-F0-9]{40}$/,
}

type LegacyData =
  | OBSSStorage.LegacyPostStruct[]
  | OBSSStorage.LegacyReactionStruct[]

function getBatchOfData(data: LegacyData, start: number, end: number) {
  return data.slice(start, end)
}

function prepareAllBatches(data: LegacyData) {
  const batchStep = 5
  const batches: LegacyData[] = []
  for (let i = 0; i < data.length; i += batchStep) {
    const batch = getBatchOfData(data, i, i + batchStep)
    batches.push(batch)
  }
  return batches
}

async function main() {
  const [deployer] = await ethers.getSigners()

  // Deploy the contract
  console.log('Deploying contracts with the account:', deployer.address)
  console.log(
    'Account balance:',
    utils.formatEther(await deployer.getBalance())
  )

  const { forwarder, vcAllowMap, founderAllowMap } = await prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      vcAllowMap: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: '0xe8c7754340b9f0efe49dfe0f9a47f8f137f70477',
      },
      founderAllowMap: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: '0x91002bd44b9620866693fd8e03438e69e01563ee',
      },
    },
  })

  const provider = ethers.provider

  const { chainId } = await provider.getNetwork()
  const chains = {
    1: 'mainnet',
    3: 'ropsten',
    4: 'rinkeby',
    5: 'goerli',
    137: 'polygon',
    80001: 'mumbai',
  } as { [chainId: number]: string }
  const chainName = chains[chainId]

  const constructorArguments = [
    forwarder,
    version,
    vcAllowMap,
    founderAllowMap,
  ] as [string, string, string, string]

  const contractName = 'OBSSStorage'
  console.log(`Deploying ${contractName}...`)
  const factory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(factory, constructorArguments, {
    initializer: 'initialize',
  })

  console.log(
    'Deploy tx gas price:',
    utils.formatEther(contract.deployTransaction.gasPrice || 0)
  )
  console.log(
    'Deploy tx gas limit:',
    utils.formatEther(contract.deployTransaction.gasLimit)
  )
  await contract.deployed()

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    contract.address
  )
  const adminAddress = await upgrades.erc1967.getAdminAddress(contract.address)

  const deployedContract = factory
    .attach(contract.address)
    .connect(provider)
    .connect(deployer)

  console.log('OBSSStorage Proxy address:', contract.address)
  console.log('Implementation address:', implementationAddress)
  console.log('Admin address:', adminAddress)

  console.log('Migrating data...')

  const { legacyPosts, legacyReactions } = await downloadData(provider)
  const legacyPostsBatches = prepareAllBatches(legacyPosts)
  const legacyReactionsBatches = prepareAllBatches(legacyReactions)

  for (let i = 0; i < legacyPostsBatches.length; i++) {
    console.log(`Loading data batch ${i}/ ${legacyPostsBatches.length}`)
    const tx = await deployedContract.migrateLegacyData(
      legacyPostsBatches[i] as OBSSStorage.LegacyPostStruct[],
      [] as OBSSStorage.LegacyReactionStruct[]
    )
    const receipt = await tx.wait()
    console.log(
      `Batch ${i} loaded `,
      `https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`
    )
  }
  for (let i = 0; i < legacyReactionsBatches.length; i++) {
    console.log(`Loading data batch ${i} / ${legacyReactionsBatches.length}`)
    const tx = await deployedContract.migrateLegacyData(
      [] as OBSSStorage.LegacyPostStruct[],
      legacyReactionsBatches[i] as OBSSStorage.LegacyReactionStruct[]
    )
    const receipt = await tx.wait()
    console.log(
      `Batch ${i} loaded `,
      `https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`
    )
  }
  console.log('Data migration done!')

  console.log('Locking data migration...')

  await deployedContract.lockDataMigration()
  const isDataLoadingLocked = await deployedContract.isDataMigrationLocked()
  if (isDataLoadingLocked) {
    console.log('Data migration locked!')
  }

  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  // Try to verify the contract on Etherscan
  console.log('Verifying contract on Etherscan')
  try {
    await run('verify:verify', {
      address: implementationAddress,
    })
  } catch (err) {
    console.log(
      'Error verifiying contract on Etherscan:',
      err instanceof Error ? err.message : err
    )
  }

  // Print out the information
  console.log(`${contractName} deployed and verified on Etherscan!`)
  console.log('Contract address:', contract.address)
  console.log(
    'Etherscan URL:',
    `https://${
      chainName !== 'polygon' ? `${chainName}.` : ''
    }polygonscan.com/address/${contract.address}`
  )
}

const legacyContractAddress = '0x9e7A15E77e5E4f536b8215aaF778e786005D0f8d'

async function downloadData(provider: Provider) {
  const legacyContract = LegacyOBSSStorage__factory.connect(
    legacyContractAddress,
    provider
  )

  console.log(legacyContract.address)
  const totalFeeds = await legacyContract.lastFeedId()
  console.log(`Total feeds count: ${totalFeeds.toNumber()}`)
  const legacyPosts: OBSSStorage.LegacyPostStruct[] = []
  const legacyReactions: OBSSStorage.LegacyReactionStruct[] = []
  const userToReaction = new Map<
    string,
    {
      postId: BigNumber
      reactionType: number
      value: BigNumber
      reactionOwner: string
    }
  >()
  for (let i = 0; i < totalFeeds.toNumber(); i++) {
    const postsInFeed = await legacyContract.lastFeedPostIds(i)
    if (postsInFeed.toNumber() === 0) continue

    const feedPosts = await legacyContract.getFeedPosts(
      i,
      0,
      postsInFeed.toNumber()
    )

    const [first] = feedPosts

    if (first) {
      const maxId = Math.max(
        ...legacyPosts.map(({ post }) => Number(post.commentsFeedId)),
        0
      )
      for (
        let prevFeed = maxId;
        prevFeed < first.commentsFeedId.toNumber();
        prevFeed += 1
      ) {
        const metadata = await legacyContract.feeds(prevFeed)
        legacyPosts.push({
          post: {
            author: '0x0000000000000000000000000000000000000000',
            metadata,
            commentsFeedId: BigNumber.from(prevFeed),
            timestamp: first.timestamp.toNumber(),
          },
          feedId: 0,
        })
      }
    }

    feedPosts.forEach(async (post: OBSSStorage.PostStructOutput) => {
      legacyPosts.push({
        post: {
          author: post.author,
          metadata: {
            digest: post.metadata.digest,
            hashFunction: post.metadata.hashFunction,
            size: post.metadata.size,
          },
          commentsFeedId: post.commentsFeedId,
          timestamp: post.timestamp.toNumber(),
        },
        feedId: i,
      })
      // Collect reactions
      try {
        const lastReactionId = await legacyContract.lastReactionIds(
          post.metadata.digest
        )
        for (
          let reactionId = 0;
          reactionId < lastReactionId.toNumber();
          reactionId++
        ) {
          const reaction = await legacyContract.reactions(
            post.metadata.digest,
            reactionId
          )

          if (
            userToReaction.has(
              `${post.commentsFeedId}-${reaction.reactionOwner}`
            ) ||
            reaction.reactionOwner ===
              '0x0000000000000000000000000000000000000000'
          )
            continue

          const currentReactionId = await legacyContract.reactionsUserToId(
            post.metadata.digest,
            reaction.reactionOwner
          )

          const currentReaction = currentReactionId.eq(reactionId)
            ? reaction
            : await legacyContract.reactions(
                post.metadata.digest,
                currentReactionId.toNumber()
              )

          const { reactionType, value, reactionOwner } = currentReaction

          userToReaction.set(
            `${post.commentsFeedId}-${reaction.reactionOwner}`,
            {
              postId: post.commentsFeedId,
              reactionType,
              value,
              reactionOwner,
            }
          )
        }
      } catch (error) {
        console.log(error)
      }
    })
  }

  const reactions = Array.from(userToReaction.values()).map((reaction) => ({
    reaction,
  }))

  legacyReactions.push(...reactions)

  const sorted = legacyPosts.sort(
    (a, b) =>
      (a.post.commentsFeedId as BigNumber).toNumber() -
      (b.post.commentsFeedId as BigNumber).toNumber()
  )

  return {
    legacyPosts: sorted,
    legacyReactions,
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

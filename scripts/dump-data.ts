import { OBSSStorage } from 'typechain'
import { cwd } from 'process'
import { ethers } from 'hardhat'
import { resolve } from 'path'
import { writeFileSync } from 'fs'

const contractAddress = '0x9e7A15E77e5E4f536b8215aaF778e786005D0f8d'

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.ETH_RPC)
  const factory = await ethers.getContractFactory('OBSSStorage')
  const contract = factory.attach(contractAddress).connect(provider)

  const totalFeeds = await contract.lastFeedId()
  console.log(`Total feeds count: ${totalFeeds.toNumber()}`)
  const legacyPosts: OBSSStorage.LegacyPostStruct[] = []
  const legacyReactions: OBSSStorage.LegacyReactionStruct[] = []

  for (let i = 0; i < 10; i++) {
    const postsInFeed = await contract.lastFeedPostIds(i)
    if (postsInFeed.toNumber() === 0) continue

    const feedPosts = await contract.getFeedPosts(i, 0, postsInFeed.toNumber())
    console.log(`Feed ID: ${i}`)
    feedPosts.forEach(async (post: OBSSStorage.PostStructOutput, j) => {
      legacyPosts.push({
        author: post.author,
        feedId: j,
        metadata: {
          digest: post.metadata.digest,
          hashFunction: post.metadata.hashFunction,
          size: post.metadata.size,
        },
        timestamp: post.timestamp.toNumber(),
      })
      // Collect reactions
      try {
        const reactionId = await contract.lastReactionIds(post.metadata.digest)
        const reaction = await contract.reactions(
          post.metadata.digest,
          reactionId
        )
        if (
          reaction.reactionOwner !==
          '0x0000000000000000000000000000000000000000'
        ) {
          legacyReactions.push({
            value: reaction.value.toNumber(),
            owner: reaction.reactionOwner,
            reactionType: reaction.reactionType,
            metadata: {
              digest: post.metadata.digest,
              hashFunction: post.metadata.hashFunction,
              size: post.metadata.size,
            },
          })
        }
      } catch (_) {
        console.log('err')
      }
    })
  }

  writeFileSync(
    resolve(cwd(), 'data', `legacy-posts.json`),
    JSON.stringify(legacyPosts)
  )
  writeFileSync(
    resolve(cwd(), 'data', `legacy-reactions.json`),
    JSON.stringify(legacyReactions)
  )
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

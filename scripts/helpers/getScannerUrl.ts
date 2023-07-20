export default function getScannerUrl(chainName: string, address: string) {
  return `https://${
    chainName === 'polygon' ? '' : `${chainName}.`
  }polygonscan.com/address/${address}`
}

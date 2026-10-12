/// Konfigurasi resmi Monad Testnet dan Alamat Smart Contract SmileOn
class MonadContracts {
  static const String networkName = 'Monad Testnet';
  static const int chainId = 10143;
  static const String rpcUrl = 'https://testnet-rpc.monad.xyz';
  static const String explorerUrl = 'https://testnet.monadexplorer.com';

  /// SmileOn Payment Hub Smart Contract Address
  static const String paymentHubAddress = '0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff';
  static const String paymentHubContract = paymentHubAddress;

  /// SmileOn NFT Smart Contract Address
  static const String nftAddress = '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48';
  static const String nftContract = nftAddress;

  /// Item ID Hashes untuk SmileOnPaymentHub
  /// keccak256("PHOTO_SESSION_STANDARD")
  static const String itemPhotoSessionStandard = '0xd9ea1ba08dc13702a0a2df36768fcfa7b322fce12d264585ec843f5454b5f8e5';
  /// keccak256("CREDIT_50")
  static const String itemCredit50 = '0x1531faee6c36746cf59aa4b7f849cf9449df5db8e7ff19946894c4897f14b620';
  /// keccak256("CREDIT_100")
  static const String itemCredit100 = '0x0d47eebe6295ea70857732a39a04f21cf47d3d0f7a0b5c1325d7e4860bcae28c';
  /// keccak256("EVENT_WEDDING_300")
  static const String itemEventWedding300 = '0xa8714eb6100ee9c558cf7b312be218c5417855b4a530eb74900a688fb5e05178';

  /// Explorer URL helpers
  static String txUrl(String txHash) => '$explorerUrl/tx/$txHash';
  static String explorerTxUrl(String txHash) => txUrl(txHash);
  static String addressUrl(String address) => '$explorerUrl/address/$address';
  static String explorerAddressUrl(String address) => addressUrl(address);
  static String paymentHubUrl() => '$explorerUrl/address/$paymentHubAddress';
  static String nftUrl() => '$explorerUrl/address/$nftAddress';
}

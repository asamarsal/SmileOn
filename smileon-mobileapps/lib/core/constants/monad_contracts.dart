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
  static const String itemPhotoSessionStandard = '0x5a2ed350eb867dbe30b21f38a0bd30e042fa5dcd30b55fc3e82cf88341a4cb18';
  /// keccak256("CREDIT_50")
  static const String itemCredit50 = '0x7505045914b82c9bf797aa8ca4453d8fc5e930838c3177675b729099c66de3ce';
  /// keccak256("CREDIT_100")
  static const String itemCredit100 = '0x8b9a394b146efab9660dcdbc0bfa8e7170295f6328bdba45e0347c83713142a1';
  /// keccak256("EVENT_WEDDING_300")
  static const String itemEventWedding300 = '0x9233a8a7b952e974a31dd572a946672d3f9802d9aa025ab175db2ae4ceb59e07';

  static const String visionUrl = 'https://testnet.monadvision.com';

  /// Explorer URL helpers
  static String txUrl(String txHash) => '$visionUrl/tx/$txHash';
  static String explorerTxUrl(String txHash) => '$explorerUrl/tx/$txHash';
  static String visionTxUrl(String txHash) => '$visionUrl/tx/$txHash';
  static String visionTokenUrl(String tokenId) => '$visionUrl/token/$nftAddress/instance/$tokenId';
  static String addressUrl(String address) => '$visionUrl/address/$address';
  static String explorerAddressUrl(String address) => '$explorerUrl/address/$address';
  static String paymentHubUrl() => '$visionUrl/address/$paymentHubAddress';
  static String nftUrl() => '$visionUrl/token/$nftAddress';
}

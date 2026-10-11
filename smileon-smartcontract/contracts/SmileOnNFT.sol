// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title SmileOnNFT
 * @author SmileOn Team
 * @notice Commemorative Photostrip NFT Collectibles on Monad Testnet (Chain ID 10143).
 * @dev Mints on-chain verifiable photo memories taken via SmileOn photobox.
 */
contract SmileOnNFT is ERC721URIStorage, Ownable2Step {
    uint256 private _nextTokenId;

    struct PhotostripMetadata {
        string sessionId;
        uint256 frameId;
        uint256 timestamp;
    }

    // Mapping tokenId -> metadata
    mapping(uint256 => PhotostripMetadata) public photostripDetails;

    event PhotostripMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        string sessionId,
        uint256 frameId,
        string tokenURI
    );

    constructor(
        address initialOwner
    ) ERC721("SmileOn Moments", "SMILE") Ownable(initialOwner) {
        _nextTokenId = 1;
    }

    /**
     * @notice Mint commemorative photostrip as NFT on Monad.
     * @param to Alamat wallet penerima.
     * @param uri IPFS atau Arweave URI untuk metadata foto.
     * @param sessionId ID sesi pemotretan unik.
     * @param frameId ID template bingkai yang digunakan.
     */
    function mintPhotostrip(
        address to,
        string calldata uri,
        string calldata sessionId,
        uint256 frameId
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        photostripDetails[tokenId] = PhotostripMetadata({
            sessionId: sessionId,
            frameId: frameId,
            timestamp: block.timestamp
        });

        emit PhotostripMinted(tokenId, to, sessionId, frameId, uri);
        return tokenId;
    }

    /**
     * @notice Mendapatkan total token yang telah di-mint.
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId - 1;
    }
}

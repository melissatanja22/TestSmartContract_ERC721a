//SPDX-License-Identifier: MIT  
pragma solidity ^0.8.11;  
  
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";  

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

  
contract TestContract is ERC721A, Ownable, Pausable {  
    using SafeMath for uint256;
    using Strings for uint256;

    event PermanentURI(string _value, uint256 indexed _id);
    string baseURI;
    string public baseExtension = ".json";
    uint public constant MAX_SUPPLY = 444;
    uint public PRICE = 0 ether;
    uint public MAX_PER_MINT = 1;
    uint public constant MAX_RESERVE_SUPPLY = 4;
    bool public revealed = false;
    string public notRevealedUri;

    address[] private whitelistedAddresses;

    constructor( 
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri) 
        ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        _pause();
    }  

    modifier mintCompliance(uint256 quantity) {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(quantity <= MAX_PER_MINT, "Cannot mint that many at once");
        require(totalMinted.add(quantity) < MAX_SUPPLY, "Not enough NFTs left to mint");
        if (whitelistedAddresses.length > 0) {
            require(isAddressWhitelisted(msg.sender), "Not on the whitelist!");
        }
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable whenNotPaused mintCompliance(quantity){
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(quantity <= MAX_PER_MINT, "Cannot mint that many at once");
        require(totalMinted.add(quantity) < MAX_SUPPLY, "Not enough NFTs left to mint");
        require(PRICE * quantity <= msg.value, "Insufficient funds sent");

        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }

    function lockMetadata(uint256 quantity) internal {
        for (uint256 i = quantity; i > 0; i--) {
            uint256 tid = totalSupply() - i;
            emit PermanentURI(tokenURI(tid), tid);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setWhitelist(address[] calldata _addressArray) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _addressArray;
    }

    function isAddressWhitelisted(address _user) private view returns (bool) {
        uint i = 0;
        while (i < whitelistedAddresses.length) {
            if(whitelistedAddresses[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721aMetadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function reveal() public onlyOwner {
      revealed = true;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        PRICE = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        MAX_PER_MINT = _newmaxMintAmount;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;

        payable(0x83D164a206Df5957aE8F4Bc0AD09AF4943087E49).transfer(balance);

        // (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        // require(os);
    }
}
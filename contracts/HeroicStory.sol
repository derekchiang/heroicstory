// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Tradable } from "./ERC721Tradable.sol";

contract HeroicStory is ERC721Tradable {
  
  /// @dev URI-related variables.
  string public _contractURI;
  string public _base;
  bool public FrozenURI;

  /// @dev 10000 is 100 %.
  uint public MAX_BPS = 10000;

  struct GameResults {
    
    uint tokenId;
    uint totalContributors;
    uint totalPool;

    address[] contributors;
    uint[] shares;

  }

  /// @dev Mapping from NFT tokenId => Game results.
  mapping(uint => GameResults) public results;

  /// @dev Events.
  event FeeReceived(address indexed payee, uint indexed amount);
  event PoolUpdated(uint indexed tokenId, uint totalPoolAmount);
  event GameResultSubmitted(uint indexed tokenId, address[] contributors, uint[] shares);
  event SharesCollected(address indexed contributor, uint indexed tokenId, uint shares, uint payout);

  /**
  *   @dev Whitelist the proxy accounts of OpenSea users so that they are automatically able to trade any item on 
  *   @dev OpenSea (without having to pay gas for an additional approval)
  **/
  constructor(
    
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  
  ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {}

  /// @dev Returns the base URI for the contract's NFTs.
  function baseTokenURI() public view override returns (string memory) {
    return _base;
  }
  
  /// @dev Returns the URI for the storefront-level metadata of the contract.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /// @dev Sets contract URI for the storefront-level metadata of the contract.
  function setContractURI(string calldata _URI) external onlyOwner {
    require(!FrozenURI, "Heroic Story: URI is frozen.");
    _contractURI = _URI;
  } 
  
  /// @dev Sets the base URI for the contract's NFTs.
  function setBasetURI(string calldata _URI) external onlyOwner {
    require(!FrozenURI, "Heroic Story: URI is frozen.");
    _base = _URI;
  }

  /// @dev Makes URI uneditable.
  function freezeURI() external {
    FrozenURI = true;
  }

  /// @dev Update the results of a game.
  function updateResults(uint _tokenId, address[] calldata _contributors, uint[] calldata _shares) external onlyOwner {
    
    require(_contributors.length == _shares.length, "Heroic Story: unequal amounts of contributors and shares");

    uint currentPool = results[_tokenId].totalPool;

    results[_tokenId] = GameResults({
      tokenId: _tokenId,
      totalContributors: _contributors.length,
      totalPool: currentPool,

      contributors: _contributors,
      shares: _shares
    });

    emit GameResultSubmitted(_tokenId, _contributors, _shares);
  }

  /// @dev Update the pool size of a game.
  function updatePool(uint _tokenId, uint _amount) external onlyOwner {
    results[_tokenId].totalPool = _amount;

    emit PoolUpdated(_tokenId, results[_tokenId].totalPool);
  }

  /// @dev Lets a contributor withraw their stake in their game NFT's accrued sales fees.
  function collectPayout(uint _tokenId) external {

    GameResults memory gameResults = results[_tokenId];

    uint idx = gameResults.contributors.length;

    for(uint i = 0; i < gameResults.contributors.length; i += 1) {
      if(gameResults.contributors[i] == msg.sender) {
        idx = i;
        break;
      }
    }

    uint payout = (gameResults.totalPool * gameResults.shares[idx]) / MAX_BPS;

    (bool success,) = (msg.sender).call{ value: payout }("");
    require(success, "Heroic Story Manager: failed payout.");

    emit SharesCollected(msg.sender, _tokenId, gameResults.shares[idx], payout);
  }
}
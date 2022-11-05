//SPDX-License-Identifier: None
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAxelarSeaNftInitializable.sol";
import "./AxelarSeaNftBase.sol";

// Use Upgradeable for minimal clone pattern but actually is is not upgradeable
abstract contract AxelarSeaNftMinterBase is OwnableUpgradeable, ReentrancyGuardUpgradeable, IAxelarSeaMinterInitializable {
  using SafeTransferLib for IERC20;

  struct AxelarSeaNftPriceData {
    uint256 mintPriceStart;
    uint256 mintPriceEnd;
    uint256 mintPriceStep;
    uint256 mintStart;
    uint256 mintEnd;
    IERC20 mintTokenAddress;
  }

  AxelarSeaProjectRegistry public registry;
  AxelarSeaNftPriceData public priceData;
  AxelarSeaNftBase public nft;
  
  mapping(address => uint256) public walletMinted;

  function _updateConfig(bytes memory data) internal virtual;

  function _updateConfigAndCheckTime(bytes memory data) internal {
    _updateConfig(data);

    require(priceData.mintEnd >= priceData.mintStart, "Invalid timestamp");
  }

  function updateConfig(
    bytes memory data
  ) public onlyOwner {
    _updateConfigAndCheckTime(data);
  }

  function initialize(
    address targetNft,
    address owner,
    bytes memory data
  ) external initializer {
    nft = AxelarSeaNftBase(targetNft);
    registry = nft.registry();

    _updateConfigAndCheckTime(data);
    _transferOwnership(owner);
    __ReentrancyGuard_init();
  }

  function recoverETH() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");

    if (!success) {
      revert TransferFailed();
    }
  }

  function recoverERC20(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  function _ensureMintLimit(address to, uint256 maxAmount, uint256 amount) internal {
    walletMinted[to] += amount;

    if (walletMinted[to] > maxAmount) {
      revert MintPerWalletLimited(maxAmount);
    }
  }
}

abstract contract AxelarSeaNftMinterWithPayment is AxelarSeaNftMinterBase {
  function _pay(address from, uint256 amount) internal virtual;

  function mintFee() public view returns(uint256) {
    return nft.mintFee();
  }

  function mintPrice() public view returns(uint256) {
    unchecked {
      if (priceData.mintPriceStep == 0) {
        return priceData.mintPriceStart;
      }

      if (block.timestamp < priceData.mintStart) {
        return priceData.mintPriceStart;
      }
      
      // block.timestamp >= mintStart
      uint256 priceChange = priceData.mintPriceStep * (block.timestamp - priceData.mintStart);
      uint256 priceDiff = priceData.mintPriceEnd <= priceData.mintPriceStart ? priceData.mintPriceStart - priceData.mintPriceEnd : priceData.mintPriceEnd - priceData.mintPriceStart;

      if (priceChange < priceDiff) {
        return priceData.mintPriceEnd <= priceData.mintPriceStart ? priceData.mintPriceStart - priceChange : priceData.mintPriceStart + priceChange; 
      } else {
        return priceData.mintPriceEnd;
      }
    }
  }
}

abstract contract AxelarSeaNftMinterWithTokenPayment is AxelarSeaNftMinterWithPayment {
  using SafeTransferLib for IERC20;

  function _pay(address from, uint256 amount) internal override {
    if (block.timestamp < priceData.mintStart || block.timestamp > priceData.mintEnd) {
      revert NotMintingTime();
    }

    if (priceData.mintPriceStart > 0 || priceData.mintPriceEnd > 0) {
      uint256 totalPrice = mintPrice() * amount;
      uint256 fee = totalPrice * mintFee() / 1e18;

      priceData.mintTokenAddress.safeTransferFrom(from, registry.feeAddress(), fee);
      priceData.mintTokenAddress.safeTransferFrom(from, nft.fundAddress(), totalPrice - fee);
    }

    if (msg.value > 0) {
      (bool success, ) = payable(msg.sender).call{value: msg.value}("");
      if (!success) {
        revert TransferFailed();
      }
    }
  }
}

abstract contract AxelarSeaNftMinterWithNativePayment is AxelarSeaNftMinterWithPayment {
  function _pay(address, uint256 amount) internal override {
    if (block.timestamp < priceData.mintStart || block.timestamp > priceData.mintEnd) {
      revert NotMintingTime();
    }

    if (priceData.mintPriceStart > 0 || priceData.mintPriceEnd > 0) {
      uint256 totalPrice = mintPrice() * amount;
      uint256 fee = totalPrice * mintFee() / 1e18;

      // Check for underflow
      uint256 totalPriceWithoutFee = totalPrice - fee;

      // Will revert if msg.value < totalPrice without using more gas for checking
      uint256 remaining = msg.value - totalPrice;

      address feeAddress = registry.feeAddress();
      address fundAddress = nft.fundAddress();

      bool success;

      assembly {
        // Transfer the ETH and store if it succeeded or not.
        success := call(gas(), feeAddress, fee, 0, 0, 0, 0)
        success := and(success, call(gas(), fundAddress, totalPriceWithoutFee, 0, 0, 0, 0))
        if remaining {
          success := and(success, call(gas(), caller(), remaining, 0, 0, 0, 0))
        }
      }

      if (!success) {
        revert TransferFailed();
      }
    }
  }
}
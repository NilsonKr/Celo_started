//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Deal is AccessControl {
    bytes32 public constant SELLER_ROL = keccak256("SELLER");
    bytes32 public constant BUYER_ROL = keccak256("BUYER");

    // Participants
    address public seller;
    address public buyer;

    // Deal stages
    bool public deposited = false;
    bool public buyerDone = false;
    bool public payed = false;

    // Deal ammount and balance already paid
    uint256 public ammount;
    uint256 public balance = 0;

    constructor(
        address _seller,
        address _buyer,
        uint256 _ammount
    ) {
        seller = _seller;
        buyer = _buyer;
        _ammount = _ammount * 1 ether;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SELLER_ROL, _seller);
        _setupRole(BUYER_ROL, _buyer);
    }

    /**
     * @notice Buyer deposite money to the contract according to the ammount
     * @dev only buyer is allowed to call this function
     * @dev The value cannot be greater than the agreed ammount
     */
    function deposit() external payable onlyRole(BUYER_ROL) {
        require(!deposited, "Ammount already deposited");
        require(
            ((balance + msg.value) * 1 ether) <= ammount,
            "Ammount is greater than expected"
        );

        balance = msg.value;
        if (balance == ammount) {
            deposited = true;
        }
    }

    /**
     * @notice Buyer confirm the deal
     * @dev only buyer is allowed to call this function
     * @dev the ammount has to be already deposited and the confirmation is not done yet
     */
    function buyerConfirmation() external onlyRole(BUYER_ROL) {
        require(deposited, "Ammount not deposited");
        require(!buyerDone, "Buyer already confirmed");

        buyerDone = true;
    }

    /**
     * @notice Seller receive the payment
     * @dev only seller is allowed to call this function
     * @dev the ammount has to be already deposited , the confirmation done yet and the payment not done yet
     */
    function withdraw() external onlyRole(SELLER_ROL) {
        require(deposited, "Ammount not deposited");
        require(buyerDone, "Buyer not confirmed");
        require(!payed, "Ammount already payed");

        payed = true;
        bool result = payable(seller).send(balance);

        if (!result) {
            revert("Error sending the withdraw");
        }
    }

    /**
     * @notice In case is needed the Admin will resolve the payment
     * @dev only Admin is allowed to call this function
     */
    function resolvedByAdmin() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payed = true;
        bool result = payable(seller).send(balance);

        if (!result) {
            revert("Error sending the withdraw");
        }
    }
}

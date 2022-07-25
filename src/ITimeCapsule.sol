// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITimeCapsule {

    struct Capsule {
        address payable admin;
        string title;
        string description;
        string logo;
        address walletAddress;
        uint256 walletBalance;
        address paymentToken;
        uint256 paymentMin;
        uint256 createdAt;
        uint256 packedAt;
        uint256 unpackedAt;
        string key;
    }

    struct Message {
        address user;
        uint256 paymentAmount;
        string encryptedMessage;
        string privateKey;
        uint256 createdAt;
    }
    
    event Create(
        address indexed admin,
        string indexed slug,
        Capsule capsule
    );

    event Insert(
        address indexed user,
        string indexed slug,
        uint256 indexed id,
        string encryptedMessage,
        uint256 paymentAmount,
        uint256 createdAt
    );

    event Decrypt(
        string indexed slug,
        string privateKey
    );

    event DecryptMessage(
        string indexed slug,
        uint256 indexed id,
        string privateKey
    );

    function create(
        string calldata slug_,
        Capsule memory capsule_
    ) external returns (bool);

    function update(
        string calldata slug_,
        string calldata title_,
        string calldata description_,
        string calldata logo_
    ) external returns (bool);

    function insert(
        string calldata slug_,
        string calldata encryptedMessage_,
        uint256 paymentAmount_
    ) external payable returns (bool);

    function encrypt(
        string calldata slug_,
        string calldata privateKeyHash_,
        address walletAddress_
    ) external payable returns (bool);

    function decrypt(
        string calldata slug_,
        string calldata privateKey_
    ) external payable returns (bool);

    function decryptMessage(
        string calldata slug_,
        uint256 id_,
        string calldata privateKey_
    ) external returns (bool);

}

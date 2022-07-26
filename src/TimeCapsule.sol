// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@timecapsule/contracts/interfaces/ITimeCapsule.sol";

error TransferFail(address from, address to, address token, uint256 amount);
error ErrorTimestamp(uint256 createdAt, uint256 packedAt, uint256 unpackedAt);
error EmptySlug(string slug);
error OnlyAdmin(address admin, address notAdmin);
error CapsuleExists(address admin);
error CapsuleNotExists(string slug, address admin);
error CapsuleOpened(uint256 blockNumber, uint256 packedAt, uint256 unpackedAt);
error CapsulePacked(uint256 blockNumber, uint256 packedAt, uint256 unpackedAt);
error CapsuleUnpacked(string privateKey);
error MessageNotExists(string slug, uint256 id, address user);
error MessageUnpacked(string privateKey);
error MessageMinPayment(uint256 paymentAmountMin, uint256 paymentAmount);
error PrivateKeyNotValid(bytes32 key1, bytes32 key2);

contract TimeCapsule is ITimeCapsule {

    address payable immutable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    mapping(string => Capsule) public capsule;
    mapping(uint256 => string) public capsules;
    uint256 public id;

    mapping(string => mapping(uint256 => Message)) public messages;
    mapping(string => uint256) public num;

    function create(
        string calldata slug_,
        Capsule memory capsule_
    ) external override returns (bool) {
        capsule_.admin = payable(
            capsule_.admin == address(0) ? msg.sender : capsule_.admin
        );
        capsule_.createdAt = block.timestamp;
        capsule_.walletAddress = address(0);
        capsule_.walletBalance = 0;
        if (
            capsule_.createdAt >= capsule_.packedAt ||
            capsule_.packedAt >= capsule_.unpackedAt
        ) {
            revert ErrorTimestamp(
                capsule_.createdAt,
                capsule_.packedAt,
                capsule_.unpackedAt
            );
        }
        if (bytes(slug_).length == 0) {
            revert EmptySlug(
                slug_
            );
        }
        if (capsule[slug_].admin != address(0)) {
            revert CapsuleExists(
                capsule[slug_].admin
            );
        }
        id++;
        capsule[slug_] = capsule_;
        capsules[id] = slug_;
        emit Create(
            capsule_.admin,
            slug_,
            capsule_
        );
        return true;
    }

    function update(
        string calldata slug_,
        string calldata title_,
        string calldata description_,
        string calldata logo_
    ) external override returns (bool) {
        if (capsule[slug_].admin != msg.sender) {
            revert CapsuleNotExists(
                slug_,
                capsule[slug_].admin
            );
        }
        if (capsule[slug_].packedAt > block.timestamp) {
            capsule[slug_].title = title_;
            capsule[slug_].logo = logo_;
        }
        capsule[slug_].description = description_;
        return true;
    }

    function insert(
        string calldata slug_,
        string calldata encryptedMessage_,
        uint256 paymentAmount_
    ) external override payable returns (bool) {
        if (capsule[slug_].paymentMin > paymentAmount_) {
            revert MessageMinPayment(
                capsule[slug_].paymentMin, 
                paymentAmount_
            );
        }
        if (capsule[slug_].createdAt <= 0) {
            revert CapsuleNotExists(
                slug_,
                capsule[slug_].admin
            );
        }
        if (capsule[slug_].packedAt < block.timestamp) {
            revert CapsulePacked(
                block.timestamp,
                capsule[slug_].packedAt,
                capsule[slug_].unpackedAt
            );
        }
        if (paymentAmount_ > 0) {
            capsule[slug_].walletBalance += paymentAmount_;
        }
        num[slug_]++;
        messages[slug_][num[slug_]] = Message(
            msg.sender,
            paymentAmount_,
            encryptedMessage_,
            "",
            block.timestamp
        );
        emit Insert(
            msg.sender, 
            slug_,
            num[slug_],
            encryptedMessage_,
            paymentAmount_,
            block.timestamp
        );

        if (capsule[slug_].paymentMin > 0) {
            _payment(
                msg.sender,
                address(this),
                capsule[slug_].paymentToken,
                paymentAmount_
            );
        }

        return true;
    }

    function decrypt(
        string calldata slug_,
        string calldata privateKey_
    ) external override payable returns (bool) {
        // bytes32 key1 = keccak256(abi.encode(
        //     _bytes32ToString(keccak256(abi.encodePacked(privateKey_)))
        // ));
        // bytes32 key2 = keccak256(abi.encode(
        //     capsule[slug_].key
        // ));
        // if (key1 != key2) {
        //     revert PrivateKeyNotValid(
        //         key1,
        //         key2
        //     );
        // }
        if (
            msg.sender != capsule[slug_].admin &&
            msg.sender != owner
        ) {
            revert CapsuleNotExists(
                slug_,
                capsule[slug_].admin
            );
        }
        if (block.timestamp < capsule[slug_].unpackedAt) {
            revert CapsulePacked(
                block.timestamp,
                capsule[slug_].packedAt,
                capsule[slug_].unpackedAt
            );
        }
        capsule[slug_].key = privateKey_;
        emit Decrypt(
            slug_, 
            privateKey_
        );

        if (capsule[slug_].walletBalance > 0) {
            (uint256 amount, uint256 fee) = _amount(slug_, 1);
            capsule[slug_].walletBalance -= amount;
            _payments(slug_, amount, fee);
        }

        return true;
    }

    function decryptMessage(
        string calldata slug_,
        uint256 id_,
        string calldata privateKey_
    ) external override returns (bool) {
        if (messages[slug_][id_].user != msg.sender) {
            revert MessageNotExists(
                slug_,
                id_,
                messages[slug_][id_].user
            );
        }
        if (
            capsule[slug_].packedAt < block.timestamp &&
            capsule[slug_].unpackedAt > block.timestamp
        ) {
            revert CapsulePacked(
                block.timestamp,
                capsule[slug_].packedAt,
                capsule[slug_].unpackedAt
            );
        }
        if (bytes(messages[slug_][id_].privateKey).length > 0) {
            revert MessageUnpacked(
                messages[slug_][id_].privateKey
            );
        }
        messages[slug_][id_].privateKey = privateKey_;
        emit DecryptMessage(
            slug_, 
            id_, 
            privateKey_
        );
        return true;
    }

    function encrypt(
        string calldata slug_,
        string calldata /* privateKeyHash_ */,
        address walletAddress_
    ) external override payable returns (bool) {
        if (
            capsule[slug_].packedAt > block.timestamp
        ) {
            revert CapsuleOpened(
                block.timestamp,
                capsule[slug_].packedAt,
                capsule[slug_].unpackedAt
            );
        }
        if (
            msg.sender != capsule[slug_].admin &&
            msg.sender != owner
        ) {
            revert OnlyAdmin(
                capsule[slug_].admin,
                msg.sender
            );
        }

        // if (capsule[slug_].unpackedAt > block.timestamp) {
        //     capsule[slug_].key = privateKeyHash_;
        // }
        if (
            capsule[slug_].walletBalance > 0 &&
            capsule[slug_].walletAddress == address(0) &&
            walletAddress_ != address(0)
        ) {
            (uint256 amount, uint256 fee) = _amount(slug_, 2);
            capsule[slug_].walletAddress = walletAddress_;
            capsule[slug_].walletBalance -= amount;
            _payments(slug_, amount, fee);
        }

        return true;
    }

    function getNumberOfCapsules() external view returns(uint256) {
        return id;
    }

    function getCapsuleBySlug(
        string calldata slug_
    ) external view returns(Capsule memory) {
        return capsule[slug_];
    }

    function getCapsuleById(
        uint256 id_
    ) external view returns(string memory slug, Capsule memory) {
        return (capsules[id_], capsule[capsules[id_]]);
    }

    function getCapsuleByIdDesc(
        uint256 id_
    ) external view returns(string memory slug, Capsule memory) {
        id_ = id > 0 && id_ > 0 && id >= id_ ? id - id_ + 1 : 0;
        return (capsules[id_], capsule[capsules[id_]]);
    }

    function getNumberOfMessagesInCapsule(
        string calldata slug_
    ) external view returns(uint256) {
        return num[slug_];
    }

    function getMessageInCapsule(
        string calldata slug_,
        uint256 id_
    ) external view returns(Message memory) {
        return messages[slug_][id_];
    }

    function _amount(
        string calldata slug_,
        uint256 dec_
    ) internal view returns(uint256 amount, uint256 fee) {
        fee = (capsule[slug_].walletBalance * 1000) / 10000;
        amount = (capsule[slug_].walletBalance - fee) / dec_;
    }

    function _payments(
        string calldata slug_,
        uint256 amount_,
        uint256 fee_
    ) internal {
        _payment(
            address(this),
            capsule[slug_].walletAddress,
            capsule[slug_].paymentToken,
            amount_
        );
        _payment(
            address(this),
            owner,
            capsule[slug_].paymentToken,
            fee_
        );
    }

    function _payment(
        address paymentSender_,
        address paymentReceiver_,
        address paymentToken_,
        uint256 paymentAmount_
    ) internal {
        bool success;
        if (paymentToken_ != address(0)) {
            success = IToken(paymentToken_).transferFrom(
                paymentSender_,
                paymentReceiver_,
                paymentAmount_
            );
            if (!success) {
                revert TransferFail(
                    paymentSender_,
                    paymentReceiver_,
                    paymentToken_,
                    paymentAmount_
                );
            }
        } else {
            // slither-disable-next-line low-level-calls
            (success,) = paymentReceiver_.call{value: paymentAmount_}("");
            if (!success) {
                revert TransferFail(
                    paymentSender_,
                    paymentReceiver_,
                    paymentToken_,
                    paymentAmount_
                );
            }
        }
    }

    function _bytes32ToString(bytes32 _bytes32) internal pure returns(string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {

            uint8 _f = uint8(_bytes32[i/2] & 0x0f);
            uint8 _l = uint8(_bytes32[i/2] >> 4);

            bytesArray[i] = _toByte(_l);
            i = i + 1;
            bytesArray[i] = _toByte(_f);
        }
        return string(bytesArray);
    }

    function _toByte(uint8 _uint8) internal pure returns(bytes1) {
        if(_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }

    receive() external payable {}
    fallback() external payable {}

}

interface IToken {
    function transferFrom(address, address, uint256) external returns (bool);
}
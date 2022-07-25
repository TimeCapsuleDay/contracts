// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "@timecapsule/contracts/TimeToken.sol";
import "@timecapsule/contracts/TimeCapsule.sol";

contract Contract is Test {

    TimeToken timeToken = new TimeToken();
    TimeCapsule timeCapsulte = new TimeCapsule();

    function setUp() public {
        timeToken.approve(address(timeCapsulte), 100 * 10 ** 6);
    }

    function testCreate() public {
        timeCapsulte.create("slug", ITimeCapsule.Capsule({
            admin: payable(address(timeCapsulte)),
            title: "Title",
            description: "Description",
            logo: "image",
            paymentToken: address(timeToken),
            paymentMin: 100,
            walletAddress: address(0),
            walletBalance: 0,
            createdAt: block.number,
            packedAt: block.number + 10,
            unpackedAt: block.number + 20,
            key: ""
        }));
        assertEq(timeCapsulte.id(), 1);
        assertEq(timeCapsulte.capsules(1), "slug");

        timeCapsulte.insert("slug", unicode"Hello #@)₴?$0", 100);
        assertEq(timeCapsulte.num("slug"), 1);
    }

}

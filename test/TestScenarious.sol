// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuxiliaryFunctions.t.sol";

contract TestScenarios is AuxiliaryFunctions {
    function test_WrongDeploymentArguments() external {
        ERC1155Store testStore1 = new ERC1155Store(dexPoolAddress, qtAddress, btAddress, startMinRate);

        vm.expectRevert();
        ERC1155Store testStore2 = new ERC1155Store(dexPoolAddress, btAddress, address(99), startMinRate);

        vm.expectRevert();
        ERC1155Store testStore3 = new ERC1155Store(dexPoolAddress, address(99), qtAddress, startMinRate);
    }

    function test_List() external {
        testStore.addLister(lister);
        vm.expectRevert();
        _createListing(lister, 0, 10, 10);
    }

    function test_ListWithApproval() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);
    }

    function test_ListRepetitiveListing() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        vm.expectRevert();
        _createListing(lister, 0, 10, 10);

        vm.expectRevert();
        _cancelListing(buyer, 0);

        _cancelListing(lister, 0);
        _createListing(lister, 0, 10, 10);
    }

    function test_Buy() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 1, false);
    }

    function testFail_RateHigherThanAcceptableMaxRate() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        testStore.setMinimumAcceptableRate(90000000000000);

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 1, false);
    }

    function test_BuySafe() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 1, false);
    }

    function test_BuySafeHigherPricePrevented() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        _approveToken(buyer, 10000);
        uint256 forMaxPriceInQT = testStore.checkListingQTPrice(0);

        vm.startPrank(buyer);
        vm.expectRevert();
        testStore.safePurchase(0, 1, (forMaxPriceInQT / 2));
        vm.stopPrank();
    }

    function test_BuyCancelledListing() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);
        _cancelListing(lister, 0);

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 1, true);
    }

    function test_BuyWithoutApproval() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        _purchaseWithTest(buyer, 0, 0, 1, true);
    }

    function test_BuyMultipleUsers() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 1, false);

        _approveToken(buyer2, 10000);
        _purchaseWithTest(buyer2, 0, 0, 2, false);
    }

    function test_BuyCompletedListing() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 10, false);

        _approveToken(buyer2, 10000);
        _purchaseWithTest(buyer2, 0, 0, 2, true);
    }

    function test_BuyAfterListerTransferedNFTs() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);

        vm.startPrank(lister);
        testNFT.safeTransferFrom(lister, buyer, 0, 10, "");
        vm.stopPrank();

        _approveToken(buyer, 10000);
        _purchaseWithTest(buyer, 0, 0, 1, true);
    }

    function test_GasUsage() external {
        testStore.addLister(lister);
        _createListingWithApproval(lister, 0, 10, 10);
        for (uint256 x = 1; x < 150; x++) {
            _createListing(lister, x, 10, 5);
        }

        _approveToken(buyer, 1000000);
        for (uint256 x = 0; x < 150; x++) {
            _purchaseWithTest(buyer, x, x, 1, false);
        }

        _approveToken(buyer2, 1000000);
        for (uint256 x = 0; x < 150; x++) {
            _purchaseWithTest(buyer2, x, x, 1, false);
        }

        uint256[] memory myList = testStore.getValidListingIDs();
        for (uint256 x; x < myList.length; x++) {}

        uint256[] memory litingIDs;
        address[] memory nftContractAddresses;
        uint256[] memory nftIDs;
        uint256[] memory quantities;
        uint256[] memory prices;

        (litingIDs, nftContractAddresses, nftIDs, quantities, prices) = testStore.getAllValidListings();
        for (uint256 x = 0; x < 90; x++) {
            _cancelListing(lister, x);
        }
        (litingIDs, nftContractAddresses, nftIDs, quantities, prices) = testStore.getAllValidListings();

        _approveToken(buyer3, 1000000);
        for (uint256 x = 90; x < 150; x++) {
            _purchaseWithTest(buyer2, x, x, 2, false);
        }
        (litingIDs, nftContractAddresses, nftIDs, quantities, prices) = testStore.getAllValidListings();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AucEngine {
    address public owner;
    uint constant DURATION = 2 days; /* constant - задается только один раз в начале сразу
                                        immutable - задается потом в конструкторе */
    uint constant FEE = 10;
    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctions;

    event AuctionCreate(uint index, string itemName, uint startingPrice, uint duration);

    event AuctionEnded(uint auction, uint finalPrice, address winner);

    constructor() {
        owner = msg.sender;
    }

    function createAuction(uint _startingPrice, uint _discountRate, string calldata _item, uint _duration) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(_startingPrice >= _discountRate * duration, "Incorrect starting price");

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreate(auctions.length - 1, _item, _startingPrice, duration);

    }

    function getPrice(uint index) public view returns(uint) {
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "stopped!");
        uint elapsed = block.timestamp - cAuction.startAt;
        uint discount = cAuction.discountRate * elapsed;
        return cAuction.startingPrice - discount;
    }

    function buy(uint index) external payable {
        Auction storage cAuction = auctions[index];
        require(!cAuction.stopped, "stopped!");
        require(block.timestamp < cAuction.endAt, "ended!");
        uint cPrice = getPrice(index);
        require(msg.value >= cPrice, "Not enough money!");
        cAuction.stopped = true;
        cAuction.finalPrice = cPrice;
        uint refund = msg.value - cPrice;
        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        cAuction.seller.transfer(
            cPrice - ((cPrice * FEE) / 100)
        );
        emit AuctionEnded(index, cPrice, msg.sender);
    }

    function withDraw(address whereWithdraw) external payable {
        require(msg.sender == owner);
        payable(whereWithdraw).transfer(msg.value);
    }
}
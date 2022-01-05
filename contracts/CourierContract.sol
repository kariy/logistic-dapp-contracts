// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./ContainerCompany.sol";

abstract contract CourierFactory {
    event NewItem(uint256 itemId);
    event ItemShipped(uint256 itemId);
    event ItemDelivered(uint256 itemId);

    enum ItemStatus {
        Processing,
        Ongoing,
        Completed,
        LostInTransit
    }

    enum ShipmentType {
        Domestic,
        International
    }

    struct Location {
        string name;
        uint256 long;
        uint256 lat;
    }

    struct Destination {
        address receiver;
        Location location;
    }

    struct Checkpoint {
        string status;
        string desc;
        address operator;
        Location location;
        uint256 timestamp;
    }

    struct Item {
        uint256 id;
        ShipmentType shipmentType;
        uint8 countryDestination;
        Destination destination;
        ItemStatus status;
        address forwardedTo;
        uint256 dateCreated;
        uint256 dateCompleted;
        uint256 price;
    }
}

contract CourierContract is Ownable, CourierFactory {
    uint256 private _totalItems = 0;

    //map the Item to its ID
    mapping(uint256 => Item) public _item;

    //  map checkpoints to Item
    mapping(uint256 => Checkpoint[]) private _itemToCheckpoints;

    modifier itemExist(uint256 id) {
        require(id > 0 && id <= _totalItems, "Item of that ID does not exist!");
        _;
    }

    function createItem(
        ShipmentType shipmentType,
        uint8 country,
        address receiver,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external onlyOwner returns (uint256) {
        _totalItems++;

        Item storage newItem = _item[_totalItems];
        newItem.id = _totalItems;
        newItem.countryDestination = country;
        newItem.destination.receiver = receiver;
        newItem.destination.location = Location(locName, long, lat);
        newItem.dateCreated = block.timestamp;
        newItem.shipmentType = shipmentType;

        emit NewItem(newItem.id);

        return newItem.id;
    }

    function addItemCheckpoint(
        uint256 itemId,
        string memory status,
        string memory desc,
        address operator,
        string memory locName,
        uint256 long,
        uint256 lat
    ) public itemExist(itemId) {
        Location memory newLoc = Location(locName, long, lat);
        Checkpoint memory newCheckpoint = Checkpoint(
            status,
            desc,
            operator,
            newLoc,
            block.timestamp
        );

        // insert checkpoint to its Item
        _itemToCheckpoints[itemId].push(newCheckpoint);
    }

    function _updateItemStatus(uint256 itemId, ItemStatus newStatus)
        private
        itemExist(itemId)
    {
        //  update status based on itemid
        _item[itemId].status = newStatus;
    }

    //  initiate shipment
    function initItemShipment(
        uint256 itemId,
        string memory status,
        string memory desc,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external itemExist(itemId) onlyOwner {
        require(
            _item[itemId].status == ItemStatus.Ongoing,
            "This item has already been shipped!"
        );

        // The operator of this checkpoint would be this contract
        // because why would you want to let someone else initiate
        // the shipment of the items?
        addItemCheckpoint(
            itemId,
            status,
            desc,
            address(this),
            locName,
            long,
            lat
        );

        _updateItemStatus(itemId, ItemStatus.Ongoing);
    }

    //transfer event
    event Transfer(address to, uint256 amount, uint256 balance);

    // Completeshipment function try buat payable?
    function completeItemShipment(
        uint256 itemId,
        string memory status,
        string memory desc,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external itemExist(itemId) {
        Item storage item = _item[itemId];

        require(
            msg.sender == item.destination.receiver,
            "Only the receiver of this item can complete the shipment!"
        );
        require(
            item.status != ItemStatus.Completed,
            "The shipment of this container is already completed!"
        );

        item.dateCompleted = block.timestamp;

        addItemCheckpoint(itemId, status, desc, msg.sender, locName, long, lat);
        _updateItemStatus(itemId, ItemStatus.Completed);
    }

    // function transferEth(address payable recipient, uint itemId)external {
    //     recipient.transfer(_item[itemId].price);
    // }

    function forwardItemToContainer(
        address containerAddress,
        uint256 itemId,
        uint256 countryCode,
        string memory status,
        string memory desc,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external itemExist(itemId) {
        ContainerCompany containerContract = ContainerCompany(containerAddress);
        containerContract.queueItem(countryCode, address(this), itemId);

        _item[itemId].forwardedTo = containerAddress;

        addItemCheckpoint(
            itemId,
            status,
            desc,
            address(this),
            locName,
            long,
            lat
        );

        _updateItemStatus(itemId, ItemStatus.Ongoing);
    }
}

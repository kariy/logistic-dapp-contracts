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
        // uint256 long;
        // uint256 lat;
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
        address payable payee; //seller
        uint256 price;
    }
}

contract CourierContract is CourierFactory {
    //item count
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
        address payee,
        uint256 price
    )
        external
        returns (
            // uint256 long,
            // uint256 lat
            uint256 _itemId
        )
    {
        // item id starts with 1
        _totalItems++;

        Item storage newItem = _item[_totalItems];
        newItem.id = _totalItems;
        newItem.countryDestination = country;
        newItem.destination.receiver = receiver;
        newItem.destination.location = Location(
            locName /*, long, lat*/
        );
        newItem.dateCreated = block.timestamp;
        newItem.shipmentType = shipmentType;
        newItem.payee = payable(payee);
        newItem.price = price;

        emit NewItem(newItem.id);

        return newItem.id;
    }

    function addItemCheckpoint(
        uint256 itemId,
        string memory status,
        string memory desc,
        address operator,
        string memory locName
    )
        public
        // uint256 long,
        // uint256 lat
        itemExist(itemId)
    {
        Location memory newLoc = Location(
            locName
            /*long, 
            lat*/
        );
        Checkpoint memory newCheckpoint = Checkpoint(
            status,
            desc,
            operator,
            newLoc,
            block.timestamp
        );

        _itemToCheckpoints[itemId].push(newCheckpoint);
    }

    function initItemShipment(
        uint256 itemId,
        string memory status,
        string memory desc,
        string memory locName
    )
        external
        itemExist(itemId)
        returns (uint256 _itemId, ItemStatus _itemstatus)
    {
        require(
            _item[itemId].status != ItemStatus.Ongoing,
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
            locName
            // long,
            // lat
        );

        emit ItemShipped(itemId);

        _updateItemStatus(itemId, ItemStatus.Ongoing);

        return (itemId, _item[itemId].status);
    }

    function completeItemShipment(
        uint256 itemId,
        string memory status,
        string memory desc,
        string memory locName
    )
        public
        payable
        itemExist(itemId)
        returns (uint256 _itemId, ItemStatus _itemstatus)
    {
        require(
            _item[itemId].status != ItemStatus.Completed,
            "This item has already been delivered!"
        );
        require(
            msg.sender == _item[itemId].destination.receiver,
            "You are not the receiver!"
        );
        require(msg.value == _item[itemId].price, "Not enough wei!");

        _item[itemId].dateCompleted = block.timestamp;

        addItemCheckpoint(
            itemId,
            status,
            desc,
            msg.sender,
            locName
            // _long,
            // _lat
        );

        address payable payee = _item[_itemId].payee;
        payee.transfer(msg.value);

        _updateItemStatus(itemId, ItemStatus.Completed);

        emit ItemDelivered(itemId);

        return (itemId, _item[itemId].status);
    }

    function setItemAsMissing(uint256 itemId)
        external
        itemExist(itemId)
        returns (uint256 _itemId, ItemStatus _itemstatus)
    {
        _updateItemStatus(itemId, ItemStatus.LostInTransit);

        return (itemId, _item[itemId].status);
    }

    function forwardItemToContainer(
        address containerAddress,
        uint256 itemId,
        uint256 countryCode,
        string memory status,
        string memory desc,
        string memory locName // uint256 _long, // uint256 _lat
    ) external returns (uint256 _itemId, address _containerAddress) {
        ContainerCompany containerContract = ContainerCompany(containerAddress);
        containerContract.queueItem(countryCode, address(this), itemId);

        _item[itemId].forwardedTo = containerAddress;

        addItemCheckpoint(
            itemId,
            status,
            desc,
            msg.sender,
            locName
            // _long,
            // _lat
        );

        _updateItemStatus(itemId, ItemStatus.Ongoing);

        return (itemId, containerAddress);
    }

    //////////////////
    ///   Getter   ///
    //////////////////

    function getCheckpointsOf(uint256 itemId)
        external
        view
        itemExist(itemId)
        returns (Checkpoint[] memory)
    {
        return _itemToCheckpoints[itemId];
    }

    function getItemOf(uint256 itemId)
        external
        view
        itemExist(itemId)
        returns (Item memory)
    {
        return _item[itemId];
    }

    function getStatusOf(uint256 itemId)
        external
        view
        itemExist(itemId)
        returns (ItemStatus)
    {
        return _item[itemId].status;
    }

    function getTotalItems() external view returns (uint256) {
        return _totalItems;
    }

    ///////////////////
    ///   Utility   ///
    ///////////////////

    function _updateItemStatus(uint256 itemId, ItemStatus newStatus)
        private
        itemExist(itemId)
    {
        _item[itemId].status = newStatus;
    }

    receive() external payable {}
}

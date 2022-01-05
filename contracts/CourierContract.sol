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
        address payee;//seller
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
        address _payee,
        uint256 _price
        // uint256 long,
        // uint256 lat
    ) external returns (uint256) {
        _totalItems++;// the item id starts with 1 ... 

        Item storage newItem = _item[_totalItems];
        newItem.id = _totalItems;
        newItem.countryDestination = country;
        newItem.destination.receiver = receiver;
        newItem.destination.location = Location(locName/*, long, lat*/);
        newItem.dateCreated = block.timestamp;
        newItem.shipmentType = shipmentType;
        newItem.payee = _payee;
        newItem.price = _price;

        emit NewItem(newItem.id);

        return newItem.id;
    }

    function addItemCheckpoint(
        uint256 itemId,
        string memory status,
        string memory desc,
        address operator,
        string memory locName
        // uint256 long,
        // uint256 lat
    ) public itemExist(itemId) {
        Location memory newLoc = Location(
            locName
            /*long, 
            lat*/);
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
        string memory locName
        // uint256 long,
        // uint256 lat
    ) external itemExist(itemId) {
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
    }

     //missing item
    function setItemAsMissing(
        uint256 itemId
        // string memory status,
        // string memory desc,
        // string memory locName
        // uint256 long,
        // uint256 lat
    ) external itemExist(itemId) {

        _updateItemStatus(itemId, ItemStatus.LostInTransit);
    }

    //transfer event
    //event Transfer(address to, uint256 amount, uint256 balance);

    //Completeshipment function try buat payable?
    function completeShipment(
        uint256 _itemId,
        string memory _status,
        string memory _desc,
        string memory _location_name
        // uint256 _long,
        // uint256 _lat
    ) public itemExist(_itemId) payable returns(uint itemId, ItemStatus itemstatus){
        require(
            _item[_itemId].status != ItemStatus.Completed,
            "This item has already been delivered!"
        );
        require(
            msg.sender == _item[_itemId].destination.receiver,
            "You are not the receiver!"
        );
        require(
            msg.value == _item[_itemId].price,
            "You are not the receiver!"
        );

        _item[_itemId].dateCompleted = block.timestamp;

        addItemCheckpoint(
            _itemId,
            _status,
            _desc,
            msg.sender, 
            _location_name
            // _long,
            // _lat
        );

        _updateItemStatus(_itemId, ItemStatus.Completed);
        emit ItemDelivered(itemId);
        return (_itemId, ItemStatus.Completed);
    }

    function payablee() external payable{
    }

    //forward item to container
    function forwardItemToContainer(
        address containerAddress,
        uint256 _itemId,
        uint256 countryCode,
        string memory _status,
        string memory _desc,
        string memory _locName
        // uint256 _long,
        // uint256 _lat
    ) external {
        ContainerCompany containerContract = ContainerCompany(containerAddress);
        containerContract.queueItem(countryCode, address(this), _itemId);

        _item[_itemId].forwardedTo = containerAddress;

        addItemCheckpoint(
            _itemId,
            _status,
            _desc,
            msg.sender,
            _locName
            // _long,
            // _lat
        );

        _updateItemStatus(_itemId, ItemStatus.Ongoing); //ongoing ke
    }

    //get all checkpoints based on item id
    function getCheckpoint(uint256 itemId)external view itemExist(itemId) returns(Checkpoint[] memory){
        return _itemToCheckpoints[itemId];
    }

    //return all item details
    function getItemDetails(uint256 itemId)external view itemExist(itemId) returns(Item memory){
        return _item[itemId];
    }

    //return the status of the item
    function getStatusItem(uint256 itemId)external view itemExist(itemId) returns(ItemStatus){
        return _item[itemId].status;
    }

}

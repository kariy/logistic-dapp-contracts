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

contract CourierContract is CourierFactory {
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
    ) external returns (uint256) {
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
    ) external itemExist(itemId) {
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

    //Completeshipment function try buat payable?
    function completeShipment(
        uint256 _itemId,
        string memory _status,
        string memory _desc,
        string memory _location_name,
        uint256 _long,
        uint256 _lat
    ) public {
        // require(
        //     msg.sender == _item[itemId].destination.receiver,
        //     "Only the receiver of this item can complete the shipment!"
        // );
        // require(
        //     _item.status != ItemStatus.Delivered,
        //     "The shipment of this container is already completed!"
        // );

        _item[_itemId].date_completed = block.timestamp;

        addItemCheckpoint(
            _itemId,
            _status,
            _desc,
            msg.sender, //betul ke?
            _location_name,
            _long,
            _lat
        );
        _updateItemStatus(_itemId, ItemStatus.Delivered);

        // if (msg.value < _item[_itemId].price) {
        //     revert("Transaction failed");
        // }

        // emit Transfer(msg.sender, msg.value, address(this).balance);

        //payTo(msg.sender.address, price);
    }

    // function transferEth(address payable recipient, uint itemId)external {
    //     recipient.transfer(_item[itemId].price);
    // }

    //forward function
    // function setAddress(address _container_address) external {
    //     //https://www.youtube.com/watch?v=YxU87o4U5iw
    //     ContainerContractAddress = _container_address;
    // }

    // function call_queueItem(uint itemId) external{
    //     ContainerCompany contract1 = ContainerCompany(ContainerContractAddress);
    //     //address(this)
    //     contract1.queueItem(_item[itemId].destination, address(this), itemId);
    //     //addCheckpoint();
    //     updateItemStatus(itemId, ItemStatus.Ongoing);
    // }

    // pandai2 kau adjust
    // yang aku buat tu basically, what the function should do
    // @param ...rest : just a placeholder kalau2 ada parameters lain yang perlu | diam ahh
    function forwardItemToContainer(
        address containerAddress,
        uint256 _itemId,
        uint256 countryCode,
        string memory _status,
        string memory _desc,
        string memory _locName,
        uint256 _long,
        uint256 _lat
    ) external {
        ContainerCompany containerContract = ContainerCompany(containerAddress);
        containerContract.queueItem(countryCode, address(this), _itemId);

        _item[_itemId].forwarded_to = containerAddress;

        addItemCheckpoint(
            _itemId,
            _status,
            _desc,
            msg.sender,
            _locName,
            _long,
            _lat
        );

        _updateItemStatus(_itemId, ItemStatus.Ongoing); //ongoing ke
    }
}

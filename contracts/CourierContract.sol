// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;
import "./Ownable.sol";
import "./ContainerCompany.sol";

contract CourierContract {

    uint item_count = 0;
    address ContainerContractAddress;

    enum ItemStatus{
        Processing,
        Shipped,
        Ongoing,
        Delivered,
        LostInTransit
    }

    enum ShipmentType{
        Domestic,
        International
    }

    struct Location{
        string location_name;
        uint long;
        uint lat;
    }

    // struct Destination{
    //     address receiver;
    //     Location location;
    // }

    struct Checkpoints{
        string status;
        string desc;
        address operator;
        Location location; 
        uint timestamp; //https://ethereum.stackexchange.com/questions/32173/how-to-handle-dates-in-solidity-and-web3
    }

    struct Item{
        uint id;
        ShipmentType shipment;
        string destination;
        ItemStatus status;
        Checkpoints[] check_point;
        uint date_created;
        uint date_completed;
        address forwarded_to;
        uint price;
    }

    mapping(uint => Item) public _item;

    function create_item(
        uint _shipment,
        string memory _destination,
        //string memory _receiver_sign,
        uint _price ) public {

        //make new item
        Item storage newItem = _item[item_count];

        //item id
        newItem.id =  item_count;

        //item shipment type
        if(_shipment == 0){
            newItem.shipment = ShipmentType.Domestic;
        }else if(_shipment == 1){
            newItem.shipment = ShipmentType.International;
        }else{
            revert("Invalid input");
        }

        //item's destination
        newItem.destination = _destination;

        //item's status
        newItem.status = ItemStatus.Processing;

        //date created
        newItem.date_created = block.timestamp;

        //newItem.receiver_sign = _receiver_sign;
        
        newItem.price = _price;
        //increment count
        item_count++;
    }

    function addCheckpoint(
        uint itemId,
        string memory _status,
        string memory _desc,
        address _operator,
        string memory _Location_name,
        uint _long,
        uint _lat
    )public{
        //fill in location
        Location memory newLoc = Location(_Location_name, _long, _lat);

        //fill in checkpoint
        Checkpoints memory newCheckPoints = Checkpoints(
            _status, //update status to ongoing
            _desc, //description of item
            _operator, //address of sender
            newLoc, //input location
            block.timestamp);//record timstamp
        
        //push checkpoint according to itemid
        _item[itemId].check_point.push(newCheckPoints);

        //update itemstatus
        updateItemStatus(itemId, ItemStatus.Ongoing);
    }

    function updateItemStatus(uint itemId, ItemStatus newStatus)public{
        //update status based on itemid
        //all_items[itemId].status = newStatus;
        _item[itemId].status = newStatus;
    }

    //initiate shipment
    function initiateShipment(
        uint256 _itemId,
        string memory _status,
        string memory _desc,
        string memory _locName,
        uint256 _long,
        uint256 _lat
    ) public{
        require(
            _item[_itemId].status == ItemStatus.Processing,
            "This container has already been shipped!"
        );

    //betul ke ni?
    addCheckpoint(_itemId, _status, _desc, msg.sender, _locName, _long, _lat);
    updateItemStatus(_itemId, ItemStatus.Shipped);
    }

    //transfer event
    event Transfer(address to, uint amount, uint balance);

    //Completeshipment function
    function completeShipment(
        uint _itemId,
        string memory _status,
        string memory _desc,
        string memory _location_name,
        uint _long,
        uint _lat
        ) public payable{

        // require(
        //     msg.sender == _item[itemId].destination.receiver,
        //     "Only the receiver of this item can complete the shipment!"
        // );
        // require(
        //     _item.status != ItemStatus.Delivered,
        //     "The shipment of this container is already completed!"
        // );   
        
        addCheckpoint(_itemId, _status, _desc, msg.sender, _location_name, _long, _lat);
        updateItemStatus(_itemId, ItemStatus.Delivered);
        
        if(msg.value < _item[_itemId].price){
        revert("Transaction failed");
        }

        emit Transfer(msg.sender, msg.value, address(this).balance);
          
        //payTo(msg.sender.address, price);
    }
   
    // function transferEth(address payable recipient, uint itemId)external {
    //     recipient.transfer(_item[itemId].price);
    // }
  
    //forward function
    function setAddress(address _container_address) external{
        //https://www.youtube.com/watch?v=YxU87o4U5iw
        ContainerContractAddress = _container_address;
    }

    function call_queueItem(uint itemId) external{
        ContainerCompany contract1 = ContainerCompany(ContainerContractAddress); 
        //address(this)
        contract1.queueItem(_item[itemId].check_point.location.location_name, address(this), itemId);
    }

    


    
}
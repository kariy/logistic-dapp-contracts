// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

contract CourierContract {

    uint item_count = 0;
    address ContainerContractAddress;

    enum ItemStatus{
        Processing,
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

    struct Checkpoints{
        string state;
        string desc;
        //address operator;
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
        string receiver_sign;
    }

    Item[] all_items;
    Item[] unshipped_items;

    function create_item(
        uint _shipment,
        string memory _destination,
        string memory _receiver_sign ) public {
        //make new item
        Item storage newItem = unshipped_items[item_count];

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

        //newItem.date_completed = 0;
        //newItem.forwarded_to = 0;

        //receiver sign ni apa?
        newItem.receiver_sign = _receiver_sign;
        
        //increment count
        item_count++;
    }

    function addCheckpoint(
        uint itemId,
        string memory _state,
        string memory _desc,
        //address _operator,
        string memory _Location_name,
        uint _long,
        uint _lat
    )public{
        //fill in location
        Location memory newLoc = Location(_Location_name, _long, _lat);

        //fill in checkpoint
        Checkpoints memory newCheckPoints = Checkpoints(_state, _desc, /*_operator,*/ newLoc, block.timestamp);
        
        //push checkpoint according to itemid
        unshipped_items[itemId].check_point.push(newCheckPoints);
    }

    function updateItemStatus(uint itemId, ItemStatus newStatus)public{
        //update status based on itemid
        unshipped_items[itemId].status = newStatus;
    }

    //aku tak faham queueItems punya function

    // function setAddress(address _container_address) external{
    //     //https://www.youtube.com/watch?v=YxU87o4U5iw
    //     ContainerContractAddress = _container_address;
    // }

    // function call_queueItem(uint itemId) external{
    //     ContainerCompany contract1 = ContainerCompany(ContainerContractAddress); 
    //     contract1.queueItem();
    // }


    
}
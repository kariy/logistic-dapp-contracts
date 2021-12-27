// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

contract CourierContract {

    //string[] all_items;
    //string[] unshipped_items;
    //mapping (uint => Item) public all_items;
    //mapping (uint => Item) public unshipped_items;
    uint item_count = 0;
    uint cp_count = 0;
    uint location_count = 0;
    address ContainerContractAddress;

    enum item_status{
        Processing,
        Ongoing,
        Delivered,
        LostInTransit
    }

    enum shipment_type{
        Domestic,
        International
    }

    struct Location{
        string location_name;
        uint long;
        uint lat;
    }

    struct Checkpoint{
        string state;
        string desc;
        address operator;
        Location location; 
        uint timestamp; //https://ethereum.stackexchange.com/questions/32173/how-to-handle-dates-in-solidity-and-web3
    }

    struct Item{
        uint id;
        shipment_type shipment;
        string destination;
        item_status status;
        Checkpoint check_point;
        uint date_created;
        uint date_completed;
        address forwarded_to;
        string receiver_sign;
    }

    Item[] public all_items;
    Item[] public unshipped_items;
    Checkpoint[] public checkpoints;
    Location[] public locations;

    function add_location(string memory _location_name, uint _long, uint _lat) public{
        locations[location_count] = Location(_location_name, _long, _lat);
        location_count++;
    }

    function add_checkpoint(
        string memory _state,
        string memory _desc,
        address _operator,
        Location memory _location,
        uint _timestamp) public{
            checkpoints[cp_count] = Checkpoint(_state, _desc, _operator, _location, _timestamp);
            cp_count++;
        }

    function create_item(
        shipment_type _shipment,
        string memory _destination,
        item_status _status,
        Checkpoint memory _check_point,
        uint _date_created,
        uint _date_completed,
        address _forwarded_to,
        string memory _receiver_sign ) public{

        unshipped_items[item_count]= Item(item_count,_shipment, _destination, _status,  _check_point, _date_created,_date_completed,_forwarded_to, _receiver_sign);
        //unshipped_items.push(name);
        item_count++;
    }

    function update_item_status(uint _id, shipment_type _shipment) public {
        for(uint i = 0; i<all_items.length ; i++){
            if(all_items[i].id == _id){
                all_items[i].shipment = _shipment;
            }else{
                revert("id not found");
            }
        }
    }

    // function setAddress(address _container_address) external{
    //     //https://www.youtube.com/watch?v=YxU87o4U5iw
    //     ContainerContractAddress = _container_address;
    //     // require(
    //     //     bytes(_container_address).length > 0, 
    //     //     bytes(_contract_id).length > 0, 
    //     //     bytes(_item_id).length > 0);
    //     // if(container_address == '' || contract_id == '' || item_id == ''){
    //     //     revert("Error, Information not complete");
    //     // }else{

    //     // }
    // }

    // function call_queue_item() external{
    //     ContainerContract contract1 = ContainerContract(ContainerContractAddress); 
    //     contract1.queue_item()
    // }

    // function display_items() view public returns(string memory){
    //    for(uint i=0 ;i <unshipped_items.length; i++){
    //        return unshipped_items[i];
    //    }
    // }

    // function update_item_status(string item_id,enum item_status){

    // }

    // function display_count() view public returns(uint){
    //    return unshipped_items.length;
    // }


    
}
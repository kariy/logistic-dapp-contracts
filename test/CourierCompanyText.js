const CourierCompany = artifacts.require("CourierCompany");

contract("CourierCompany", ()=> {
    let courierCompany; // deployement of contract
    let item1;
    let checkpoint1;
    //let initiateShipment;
    let forwardToContainer;
    let completeShipment; 
    before(async ()=>{
        courierCompany = await CourierCompany.deployed();
        item1 = await courierCompany.createItem("1","1","0x5d121b0f255b44c9e24c982696706395da9e4c22","Selangor, Malaysia","0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC","10");
        forwardToContainer = await courierCompany.forwardItemToContainer("0xE05aCF9acC21430cC863b6c6EC8d3c048b24Bbb5","1","1","Forwarded to container","Container to Malaysia","Malaysia");
        //initiateShipment = await courierCompany.initItemShipment("1","Item's shipment is being initiated","Preparing to ship","China, Shenzen Sorting Centre");
        checkpotrufint1 = await courierCompany.addItemCheckpoint("1","Checkpoint 1","First Checkpoint","0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C","Kuala Lumpur Sorting Centre");
        completeShipment = await courierCompany.completeItemShipment("1","Item arrived safely","Received hand to hand","Bandar Mahkota Banting, Selangor");


    })

    it("Should add 1 item successfully...", async ()=> {
        let viewItem = await courierCompany.getTotalItems();
        assert.equal(viewItem, 1);
    })

    it("Should forward item to container...", async ()=> {
        let viewContainer = await courierCompany.getCheckpointsOf("1");
        assert.equal(viewContainer[0].status, "Forwarded to container");
        //console.log(viewInit);
    })

    it("Should add 1 checkpoint to item...", async ()=> {
        let viewCheckpoint = await courierCompany.getCheckpointsOf("1");
        assert.equal(viewCheckpoint[1].status, "Checkpoint 1");
    })

    it("Should return status of item...", async ()=> {
        let viewItemStatus = await courierCompany.getStatusOf("1");
        assert.equal(viewItemStatus, 1);
    })
    
})
const CourierCompany = artifacts.require("CourierCompany");

contract("CourierCompany", ()=> {
    it("Should add 1 item successfully", async ()=> {
        let courierCompany = await CourierCompany.deployed();
        await courierCompany.createItem("1","1","0xdD870fA1b7C4700F2BD7f44238821C26f7392148","Selangor, Malaysia","0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC","10000");
        let viewItem = await courierCompany.getTotalItems();
        assert.equal(viewItem, 1);
    })

    it("Should add 1 checkpoint to item with id 1 successfully", async ()=> {
        let courierCompany = await CourierCompany.deployed();
        await courierCompany.addItemCheckpoint("1","Checkpoint 1","First Checkpoint","0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C","Kuala Lumpur Sorting Centre");
        let viewCheckpoint = await courierCompany.getCheckpointsOf("1");
        console.log(viewCheckpoint[5]);
        let expectedResult = "Checkpoint 1";
        assert.equal(viewCheckpoint.status, expectedResult);
    })
    
})
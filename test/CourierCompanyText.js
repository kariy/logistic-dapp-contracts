const CourierCompany = artifacts.require("CourierCompany");

contract("CourierCompany", ()=> {
    it("Should add 1 item successfully", async ()=> {
        let courierCompany = await CourierCompany.deployed();
        let addItem = await courierCompany.createItem("1","1","0xdD870fA1b7C4700F2BD7f44238821C26f7392148","Selangor, Malaysia","0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC","10000");
        //console.log(addItem);
        let viewItem = await courierCompany.getItemOf('1');
        //console.log(viewItem);
        assert.equal(addItem.itemId, viewItem.itemId);
    })
})
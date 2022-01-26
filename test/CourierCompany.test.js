const CourierCompany = artifacts.require("CourierCompany");
const ContainerCompany = artifacts.require("ContainerCompany");

contract("CourierCompany", () => {
    let courierCompany;
    let item1;
    let item2;
    let missingItem;
    let checkpoint1;
    let forwardToContainer;
    let completeShipment;

    before(async () => {
        //deploy contract
        courierCompany = await CourierCompany.deployed();

        //entering test case value into function
        item1 = await courierCompany.createItem(
            "1",
            "1",
            "0x5d121b0f255b44c9e24c982696706395da9e4c22",
            "Selangor, Malaysia",
            "0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC",
            "10000"
        );
        item2 = await courierCompany.createItem(
            "0",
            "2",
            "0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C",
            "Singapore",
            "0xdD870fA1b7C4700F2BD7f44238821C26f7392148",
            "500"
        );
        forwardToContainer = await courierCompany.forwardItemToContainer(
            ContainerCompany.address,
            "1",
            "1",
            "Forwarded to container",
            "Container to Malaysia",
            "Malaysia"
        );
        checkpoint1 = await courierCompany.addItemCheckpoint(
            "1",
            "Checkpoint 1",
            "First Checkpoint",
            "0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C",
            "Kuala Lumpur Sorting Centre"
        );
        completeShipment = await courierCompany.completeItemShipment(
            "1",
            "Item arrived safely",
            "Received hand to hand",
            "Bandar Mahkota Banting, Selangor",
            { value: web3.utils.toWei("10000", "wei") }
        );
        missingItem = await courierCompany.setItemAsMissing("2");
    });

    it("Should add 1 item successfully...", async () => {
        let addItem = await courierCompany.getTotalItems();
        assert.notEqual(addItem, 0);
    });

    it("Should forward item to container...", async () => {
        let viewContainer = await courierCompany.getCheckpointsOf("1");
        assert.equal(viewContainer[0].status, "Forwarded to container");
    });

    it("Should add 1 checkpoint to item...", async () => {
        let viewCheckpoint = await courierCompany.getCheckpointsOf("1");
        assert.equal(viewCheckpoint[1].status, "Checkpoint 1");
    });

    it("Should complete shipment of item (payable function)...", async () => {
        let viewItemStatus = await courierCompany.getStatusOf("1");
        assert.equal(viewItemStatus, 2); //return completed [2]
    });

    it("Should set item as missing...", async () => {
        let viewItemStatus1 = await courierCompany.getStatusOf("2");
        assert.equal(viewItemStatus1, 3); //return Lost in transit [2]
    });
});

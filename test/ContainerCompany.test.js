const CourierCompany = artifacts.require("CourierCompany");
const ContainerCompany = artifacts.require("ContainerCompany");

contract("ContainerCompany", function (account) {
    let courierCompany;
    let containerCompany;

    before(async () => {
        courierCompany = await CourierCompany.deployed();
        containerCompany = await ContainerCompany.deployed();

        await courierCompany.createItem(
            "1", // shipment type
            "1", // country destination, malaysia = 1
            "0x39312DB87500fE575E56d9b8B1F15f7b961a9B44", // receiver
            "Selangor, Malaysia",
            "0x5f4acD291A08f8568064120D32De8c8977c1e065", // payee
            "10000" // item price
        );

        await courierCompany.forwardItemToContainer(
            containerCompany.address,
            "1", // item id
            "1", // malaysia = 1
            "Forwarded to container",
            "Container to Malaysia",
            "Shenzhen, China" // checkpoint location
        );

        await containerCompany.createContainer(
            1, // shipment type
            1, // country destination, malaysia = 1
            "0x5f4acD291A08f8568064120D32De8c8977c1e065", // receiver
            "Port Klang" // location name
        );
    });

    it("contract deployed successfully", async function () {
        const address = await containerCompany.address;

        assert.notEqual(address, 0x0);
        assert.notEqual(address, "");
        assert.notEqual(address, null);
        assert.notEqual(address, undefined);
    });

    it("total container", async function () {
        const total = await containerCompany.getTotalContainers();

        assert.equal(total, 1, "total container is not 1");
    });

    it("item inserted in container", async function () {
        const containerItems = await containerCompany.getItemsOf("1");
        const item = containerItems[0];

        const courierAddress = await courierCompany.address;
        const itemInCourier = await courierCompany.getItemOf("1");

        assert.equal(containerItems.length, 1);
        assert.equal(item.courierAddress, courierAddress, "wrong courier item");
        assert.equal(item.courierItemId, itemInCourier.id, "wrong item id");
    });

    it("initiate container shipment", async function () {
        await containerCompany.initContainerShipment(
            1,
            "Container shipment started",
            "Container is shipped out from main port",
            "Shenzhen, China"
        );

        const container = await containerCompany.getContainerOf("1");

        assert.notEqual(container.status, 0, "container status is processing");
        assert.equal(container.status, 1, "container is not ongoing");
    });

    it("complete container shipment", async function () {
        await containerCompany.completeContainerShipment(
            "1",
            "Shipment completed",
            "Container arrived at destination",
            "Port Klang"
        );

        const container = await containerCompany.getContainerOf("1");

        assert.equal(
            container.status,
            2,
            "container shipment still not complete"
        );
    });
});

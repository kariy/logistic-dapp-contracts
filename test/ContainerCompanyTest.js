const ContainerCompany = artifacts.require("ContainerCompany");

contract('CourierCompany', ()=>{
    let contract;
    before(async ()=>{
        contract = await ContainerCompany.deployed();
    });

    it('Deployed successfully', async()=>{
        const address = await contract.address;
        assert.notEqual(address, "");
        console.log(address);
    })
})
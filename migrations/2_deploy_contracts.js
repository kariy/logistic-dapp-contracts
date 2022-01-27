const ContainerCompany = artifacts.require("ContainerCompany");

module.exports = function (deployer) {
    deployer.deploy(ContainerCompany);
};

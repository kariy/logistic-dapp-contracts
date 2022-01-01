pragma solidity >=0.7.0;

import "./Ownable.sol";

abstract contract ContainerFactory {
    event NewContainer(uint256 id, uint256 countryDestination);
    // event NewContainerCheckpoint(uint256 id, string state);

    enum ContainerStatus {
        Processing,
        Shipped,
        Completed,
        LostInTransit
    }

    struct ContainerItem {
        address courierAddress;
        uint256 courierItemId;
        uint256 dateCreated;
    }

    struct Location {
        string name;
        uint256 long;
        uint256 lat;
    }

    struct Checkpoint {
        string state;
        string desc;
        address operator;
        Location location;
        uint256 timeStamp;
    }

    struct Destination {
        address receiver;
        Location location;
    }

    struct Container {
        uint256 country;
        // address id;
        Destination destination;
        ContainerStatus status;
        // ContainerItem[] items;
        Checkpoint[] checkpoints;
        uint256 dateCreated;
        uint256 dateCompleted;
    }
}

contract ContainerCompany is Ownable, ContainerFactory {
    /// @dev List of Item which are yet to be inserted into a Container, according to their country code
    /// @dev All Item object forwarded to this contract will be inserted here.
    mapping(uint256 => ContainerItem[]) private _countryToItemQueues;

    /// @dev To check whether a container with a particular ID exist or not
    mapping(uint256 => bool) private _containerCheck;

    uint256 private _totalContainers = 0;

    /// @notice A table of all Container based on its ID
    /// @dev ID >= 1
    mapping(uint256 => Container) private _container;

    /// @dev List of items inserted into a container
    mapping(uint256 => ContainerItem[]) private _containerToItems;

    // Container[] private _container;

    modifier containerExist(uint256 id) {
        require(
            id >= 0 && id < _totalContainers,
            "Container of that ID does not exist!"
        );
        _;
    }

    /// @notice Create a new Container
    /// @dev Container ID starts from 1
    /// @param country The country 3 digits code
    /// @return ID of the Container
    function createContainer(
        uint256 country,
        address receiver,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external onlyOwner returns (uint256) {
        _totalContainers++;

        Container storage newContainer = _container[_totalContainers];
        newContainer.country = country;
        newContainer.destination.receiver = receiver;
        newContainer.destination.location = Location(locName, long, lat);
        newContainer.dateCreated = block.timestamp;

        uint256 newContainerId = _totalContainers;

        // insert all queued Items of countryCode into this Container
        _unqueueItemsToContainer(newContainerId);

        emit NewContainer(_totalContainers, country);

        return _totalContainers;
    }

    /// @dev Queue Item (according to their country destination) for Container insertion
    /// @param courierAddr Address of the Courier contract that the Item belongs to.
    /// @param courierItemId Id of the Item inside the Courier contract.
    function queueItem(
        uint256 countryDest,
        address courierAddr,
        uint256 courierItemId
    ) external {
        ContainerItem memory newContainerItem = ContainerItem(
            courierAddr,
            courierItemId,
            block.timestamp
        );

        _countryToItemQueues[countryDest].push(newContainerItem);
    }

    function addContainerCheckpoint(
        uint256 containerId,
        string memory state,
        string memory desc,
        address operator,
        string memory locName,
        uint256 long,
        uint256 lat
    ) public containerExist(containerId) returns (bool) {
        Location memory loc = Location(locName, long, lat);
        Checkpoint memory newCheckpoint = Checkpoint(
            state,
            desc,
            operator,
            loc,
            block.timestamp
        );

        _container[containerId].checkpoints.push(newCheckpoint);

        // emit NewContainerCheckpoint(containerId, state);

        return true;
    }

    // owner only function
    function initShipmentOf(
        uint256 containerId,
        string memory state,
        string memory desc,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external containerExist(containerId) onlyOwner {
        Container storage container = _container[containerId];

        require(
            container.status == ContainerStatus.Processing,
            "This container has already been shipped!"
        );

        // set this contract address
        addContainerCheckpoint(
            containerId,
            state,
            desc,
            owner(),
            locName,
            long,
            lat
        );

        _updateContainerStatus(containerId, ContainerStatus.Shipped);
    }

    function completeShipmentOf(
        uint256 containerId,
        string memory state,
        string memory desc,
        string memory locName,
        uint256 long,
        uint256 lat
    ) external containerExist(containerId) {
        Container storage container = _container[containerId];

        require(
            msg.sender == container.destination.receiver,
            "Only the receiver of this container can complete the shipment!"
        );
        require(
            container.status != ContainerStatus.Completed,
            "The shipment of this container is already completed!"
        );

        addContainerCheckpoint(
            containerId,
            state,
            desc,
            msg.sender,
            locName,
            long,
            lat
        );

        _updateContainerStatus(containerId, ContainerStatus.Completed);
    }

    //////////////////
    ///   Getter   ///
    //////////////////

    function getStatusOfContainer(uint256 containerId)
        public
        view
        returns (ContainerStatus)
    {
        return _container[containerId].status;
    }

    function getItemOfContainer(uint256 containerId)
        external
        view
        returns (ContainerItem[] memory)
    {
        return _containerToItems[containerId];
    }

    ///////////////////
    ///   Utility   ///
    ///////////////////

    function _updateContainerStatus(
        uint256 containerId,
        ContainerStatus newStatus
    ) private containerExist(containerId) {
        Container storage container = _container[containerId];
        container.status = newStatus;
    }

    function _unqueueItemsToContainer(uint256 containerId) private {
        uint256 countryCode = _container[containerId].country;

        ContainerItem[] storage qItems = _countryToItemQueues[countryCode];
        // insert all queued Items of countryCode into this Container
        for (uint256 i = 0; i < qItems.length; i++) {
            _container[containerId].items.push(qItems[i]);
        }

        // clear queue
        delete _countryToItemQueues[countryCode];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Ownable.sol";

abstract contract ContainerFactory {
    event NewContainer(uint256 containerId);
    event ContainerShipped(uint256 containerId);
    event ContainerDelivered(uint256 containerId);

    enum ContainerStatus {
        Processing,
        Ongoing,
        Completed,
        LostInTransit
    }

    enum ShipmentType {
        Domestic,
        International
    }

    struct ContainerItem {
        address courierAddress;
        uint256 courierItemId;
        uint256 dateCreated;
    }

    struct Location {
        string name;
        // uint256 long;
        // uint256 lat;
    }

    struct Checkpoint {
        string status;
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
        uint256 id;
        ShipmentType shipmentType;
        uint8 countryDestination;
        Destination destination;
        ContainerStatus status;
        uint256 dateCreated;
        uint256 dateCompleted;
    }
}

contract ContainerCompany is Ownable, ContainerFactory {
    /// @dev List of Item which are yet to be inserted into a Container, according to their country code
    /// @dev All Item object forwarded to this contract will be inserted here.
    mapping(uint256 => ContainerItem[]) private _countryToItemQueues;

    uint256 private _totalContainers = 0;

    /// @notice A table of all Container based on its ID
    /// @dev ID >= 1
    mapping(uint256 => Container) private _container;

    /// @dev List of items inserted into a container
    mapping(uint256 => ContainerItem[]) private _containerToItems;

    /// @dev Container checkpoints
    mapping(uint256 => Checkpoint[]) private _containerToCheckpoints;

    modifier containerExist(uint256 id) {
        require(
            id > 0 && id <= _totalContainers,
            "Container of that ID does not exist!"
        );
        _;
    }

    /// @notice Create a new Container
    /// @dev Container ID starts from 1
    function createContainer(
        ShipmentType shipmentType,
        uint8 country,
        address receiver,
        string memory locName
    )
        external
        onlyOwner
        returns (uint256 _containerId, ContainerStatus _status)
    {
        _totalContainers++;

        Container storage newContainer = _container[_totalContainers];
        newContainer.id = _totalContainers;
        newContainer.countryDestination = country;
        newContainer.destination.receiver = receiver;
        newContainer.destination.location = Location(locName);
        newContainer.dateCreated = block.timestamp;
        newContainer.shipmentType = shipmentType;

        // insert all queued Items of countryCode into this Container
        _unqueueItemsToContainer(newContainer.id);

        emit NewContainer(newContainer.id);

        return (newContainer.id, newContainer.status);
    }

    /// @dev Queue Item (according to their country destination) for Container insertion
    /// @param courierAddr Address of the Courier contract that the Item belongs to.
    /// @param courierItemId Id of the Item inside the Courier contract.
    function queueItem(
        uint256 countryDest, //kenapa country destination tu uint256? COUNTRY CODE
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
        string memory status,
        string memory desc,
        address operator,
        string memory locName
    ) public containerExist(containerId) returns (bool) {
        Location memory loc = Location(locName);
        Checkpoint memory newCheckpoint = Checkpoint(
            status,
            desc,
            operator,
            loc,
            block.timestamp
        );

        _containerToCheckpoints[containerId].push(newCheckpoint);

        return true;
    }

    function initContainerShipment(
        uint256 containerId,
        string memory checkpointStatus,
        string memory checkpointDesc,
        string memory checkpointLocName
    )
        external
        containerExist(containerId)
        onlyOwner
        returns (uint256 _containerId, ContainerStatus _status)
    {
        Container storage container = _container[containerId];

        require(
            container.status == ContainerStatus.Processing,
            "This container has already been shipped!"
        );

        addContainerCheckpoint(
            containerId,
            checkpointStatus,
            checkpointDesc,
            address(this),
            checkpointLocName
        );

        _updateContainerStatus(container.id, ContainerStatus.Ongoing);

        emit ContainerShipped(container.id);

        return (container.id, container.status);
    }

    function completeContainerShipment(
        uint256 containerId,
        string memory checkpointStatus,
        string memory checkpointDesc,
        string memory checkpointLocName
    )
        external
        containerExist(containerId)
        returns (uint256 _containerId, ContainerStatus _status)
    {
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
            checkpointStatus,
            checkpointDesc,
            msg.sender,
            checkpointLocName
        );

        _updateContainerStatus(container.id, ContainerStatus.Completed);

        emit ContainerDelivered(container.id);

        return (container.id, container.status);
    }

    function setContainerAsMissing(uint256 containerId)
        external
        containerExist(containerId)
        onlyOwner
        returns (uint256 _containerId, ContainerStatus _status)
    {
        Container storage container = _container[containerId];

        require(
            container.status != ContainerStatus.Completed,
            "The shipment of this container is already completed!"
        );

        _updateContainerStatus(container.id, ContainerStatus.LostInTransit);

        return (container.id, container.status);
    }

    //////////////////
    ///   Getter   ///
    //////////////////

    function getTotalContainers() external view returns (uint256) {
        return _totalContainers;
    }

    function getContainerOf(uint256 containerId)
        external
        view
        containerExist(containerId)
        returns (
            uint256 id,
            ShipmentType shipmentType,
            uint8 countryDestination,
            Destination memory destination,
            ContainerStatus status,
            uint256 dateCreated,
            uint256 dateCompleted
        )
    {
        Container storage container = _container[containerId];

        return (
            container.id,
            container.shipmentType,
            container.countryDestination,
            container.destination,
            container.status,
            container.dateCreated,
            container.dateCompleted
        );
    }

    function getStatusOf(uint256 containerId)
        public
        view
        containerExist(containerId)
        returns (ContainerStatus)
    {
        return _container[containerId].status;
    }

    function getItemsOf(uint256 containerId)
        external
        view
        containerExist(containerId)
        returns (ContainerItem[] memory)
    {
        return _containerToItems[containerId];
    }

    function getCheckpointsOf(uint256 containerId)
        external
        view
        containerExist(containerId)
        returns (Checkpoint[] memory)
    {
        return _containerToCheckpoints[containerId];
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

    function _dequeueItemsToContainer(uint256 containerId) private {
        uint8 countryCode = _container[containerId].countryDestination;

        ContainerItem[] storage qItems = _countryToItemQueues[countryCode];

        // insert all queued Items of countryCode into this Container
        for (uint256 i = 0; i < qItems.length; i++) {
            _containerToItems[containerId].push(qItems[i]);
        }

        // clear queue
        delete _countryToItemQueues[countryCode];
    }
}

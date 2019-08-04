pragma solidity ^0.5.10;

import './IERC20.sol';
import './Ownable.sol';

contract rideshare is Ownable {

    struct driver {
        string ID;
        uint successfultrips;
        uint trips;
        uint rate;
        bool tripAccepted;
        bool onTrip;
        bool tripEnded;
    }

    struct passenger {
        address passengerAddress;
        string ID;
        bool driverMet;
        bool tripEnd;
    }

    struct ride {
        uint rideNumber;
        address passengerAcct;
    }

    struct Locked {
        address owner;
        uint unlockAfter;
        uint amount;
        IERC20 token;
    }

    Locked[] public locker;

    ride[] public rides;
    uint public rideCount;

    mapping (address => driver) drivers;
    mapping (address => passenger) passengers;

    event tripStartRequest(string ID, address passengerAcct);
    event tripStarted(uint timestamp, uint rate);
    event tripEndRequest(string ID, address passengerAcct);
    event tripCompleted(uint timestamp, uint cost);

    enum RideStatus {init, avaliable, ontrip}
    RideStatus public status = RideStatus.init;

    function registerDriver(address _driver, string memory _ID, uint _rate) public onlyOwner {
        drivers[_driver].ID = _ID;
        drivers[_driver].successfultrips = 0;
        drivers[_driver].trips = 0;
        drivers[_driver].rate = _rate;
        drivers[_driver].tripAccepted = false;
        drivers[_driver].onTrip = false;
        drivers[_driver].tripEnded = false;
    }

    /* Functions below are called by driver only. */
    function updateDriverRate(uint _rate) public {
        drivers[msg.sender].rate = _rate;
    }

    function tripAccept() public {
        drivers[msg.sender].tripAccepted = true;
    }

    function tripCompletionRequest() public {
        drivers[msg.sender].tripEnded = true;
    }
    /* Functions above are called by driver only. */

    /* Functions below are called by passenger only. */
    function tripRequest(string memory _ID) public {
        passengers[msg.sender].passengerAddress = msg.sender;
        passengers[msg.sender].ID = _ID;
        passengers[msg.sender].driverMet = false;
        passengers[msg.sender].tripEnd = false;

        emit tripStartRequest(_ID, msg.sender);
    }

    function tripStart(uint _rideNumber, address _token, address _driverKey, uint _cost) public {
        require(drivers[_driverKey].tripAccepted, "Driver did not accept trip");
        rides.push(ride(_rideNumber, msg.sender));
        passengers[msg.sender].driverMet = true;
        lock(_token, _cost, 1);
        drivers[_driverKey].trips++;
        drivers[_driverKey].onTrip = true;
        emit tripStarted(block.timestamp, drivers[_driverKey].rate);
    }

    function tripCompletion(address _driverKey) public {
        drivers[_driverKey].successfultrips++;
        passengers[msg.sender].tripEnd = true;
        emit tripEndRequest(passengers[msg.sender].ID, msg.sender);
    }

    function tripEnd(address _driverKey, uint _cost, uint _index) public {
        require(passengers[msg.sender].tripEnd, "Trip not ended");
        unlock(_index, _driverKey);
        emit tripCompleted(block.timestamp, _cost);
    }
    /* Functions above are called by passenger only. */

    /* Getter functions below */
    function getDriver(address _driver) public view returns (
        string memory ID,
        uint successfultrips,
        uint trips,
        uint rate,
        bool tripAccepted,
        bool onTrip,
        bool tripEnded
    ) {
        driver memory driverFetch = drivers[_driver];
        return (
                driverFetch.ID,
                driverFetch.successfultrips,
                driverFetch.trips,
                driverFetch.rate,
                driverFetch.tripAccepted,
                driverFetch.onTrip,
                driverFetch.tripEnded
            );
        }

    function getPassenger(address _passenger) public view returns (
        address passengerAddress,
        string memory ID,
        bool driverMet,
        bool tripEnd
    ) {
        passenger memory passengerFetch = passengers[_passenger];
        return (
            passengerFetch.passengerAddress,
            passengerFetch.ID,
            passengerFetch.driverMet,
            passengerFetch.tripEnd
        );
    }

    function lock(address _token, uint256 amount, uint256 lockTime) public {
        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");
        locker.push(Locked(msg.sender, block.number+lockTime, amount, token));
    }

    function unlock(uint256 index, address _driver) public {
        Locked memory locked = locker[index];
        require(block.number > locked.unlockAfter, "Not ready");
        require(locked.owner == msg.sender, "Not owner of locked tokens");
        delete locker[index];
        locked.token.transfer(_driver, locked.amount);
    }
}
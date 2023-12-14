// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AirbnbContract {
    address public host;
    address public occupant;

    // Usages
    uint256 public gasUsage;
    uint256 public electricityUsage;
    uint256 public waterUsage;

    // Rates
    uint256 public gasRate = 0.0014 ether; // Adjust the rates as needed
    uint256 public electricityRate = 0.0016 ether;
    uint256 public waterRate = 0.0011 ether;

    uint256 public deposit = 0.0111 ether;


    enum ContractState { NotActive, Active, Deposited, Calculated }
    ContractState public contractState;

    event FundsTransferred(address indexed recipient, uint256 amount);
    event BillCalculated(address indexed recipient, uint256 totalBill, uint256 deposit, uint256 change);

    modifier onlyHost() {
        require(msg.sender == host, "Only the host can call this function");
        _;
    }

    modifier onlyOccupant() {
        require(msg.sender == occupant, "Only the occupant can call this function");
        _;
    }

    constructor() {
        host = msg.sender;
        contractState = ContractState.NotActive;
    }

    function setOccupant(address _occupant) external onlyHost {
        require(contractState == ContractState.NotActive, "Contract is already active");
        occupant = _occupant;
        contractState = ContractState.Active;
    }

    function withdrawAmount() external payable onlyOccupant {
        require(contractState == ContractState.Active, "Contract is already Notactive and there is no Occupant Address");
        require(msg.value >= deposit, "Insufficient funds");
        emit FundsTransferred(occupant, msg.value);
        contractState = ContractState.Deposited;
    }

    function trackUtilities(uint256 _gasUsage, uint256 _electricityUsage, uint256 _waterUsage) external onlyHost {
        require(contractState == ContractState.Deposited, "Contract not deposited");
        gasUsage += _gasUsage;
        electricityUsage += _electricityUsage;
        waterUsage += _waterUsage;
    }

    function calculateBill() external onlyHost {
        require(contractState == ContractState.Deposited, "Contract not in the correct state");

        // Calculate the total bill based on usage and rates
        uint256 totalBill = (gasUsage * gasRate) + (electricityUsage * electricityRate) + (waterUsage * waterRate);

        // Get the amount already deposited by the occupant
        uint256 currentDeposit = address(this).balance;

        // Calculate the change to be returned
        uint256 change = 0;
        if (currentDeposit > totalBill) {
            change = currentDeposit - totalBill;
            payable(occupant).transfer(change);
            payable(host).transfer(totalBill);
        }

        // Reset the usage counters
        gasUsage = 0;
        electricityUsage = 0;
        waterUsage = 0;

        emit BillCalculated(occupant, totalBill, currentDeposit, change);
        contractState = ContractState.Calculated;
    }

    function getContractState() external view returns (ContractState) {
        return contractState;
    }
}
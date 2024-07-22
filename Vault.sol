// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    struct Dinosaur {
        string name;
        uint power;
        uint price;
    }

    Dinosaur[] public dinosaurs;
    mapping(address => uint[]) public userDinosaurs;
    mapping(address => uint) public userLevel;

    event DinosaurPurchased(address indexed user, uint dinosaurId);
    event DinosaurSent(address indexed from, address indexed to, uint dinosaurId);
    event TokensBurned(address indexed user, uint amount);
    event LevelUp(address indexed user, uint newLevel);

    uint8 public constant TOKEN_DECIMALS = 18;

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
        _initializeDinosaurs();
    }

    function _initializeDinosaurs() internal {
        dinosaurs.push(Dinosaur("T-Rex", 100, 1000));
        dinosaurs.push(Dinosaur("Stegosaurus", 80, 800));
        dinosaurs.push(Dinosaur("Velociraptor", 90, 900));
        dinosaurs.push(Dinosaur("Triceratops", 85, 850));
        dinosaurs.push(Dinosaur("Spinosaurus", 110, 1100));
        dinosaurs.push(Dinosaur("Brachiosaurus", 95, 950));
    }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint _amount) external {
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }
        _mint(msg.sender, shares);
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external {
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.safeTransfer(msg.sender, amount);
    }

    function buyDinosaur(uint dinosaurId) external {
        require(dinosaurId < 6, "Invalid dinosaurId");
        Dinosaur memory dino = dinosaurs[dinosaurId];
        require(token.balanceOf(msg.sender) >= dino.price, "Not enough UTH");
        token.safeTransferFrom(msg.sender, address(this), dino.price);
        userDinosaurs[msg.sender].push(dinosaurId);
        emit DinosaurPurchased(msg.sender, dinosaurId);
    }

    function sendDinosaur(address to, uint dinosaurId) external {
        require(dinosaurId < 6, "Invalid dinosaurId");
        userDinosaurs[to].push(dinosaurId);
        uint[] storage dinos = userDinosaurs[msg.sender];
        for (uint i = 0; i < dinos.length; i++) {
            if (dinos[i] == dinosaurId) {
                dinos[i] = dinos[dinos.length - 1];
                dinos.pop();
                break;
            }
        }
        emit DinosaurSent(msg.sender, to, dinosaurId);
    }

    function burnTokens(uint amount) external {
        token.safeTransferFrom(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount);
    }

    function levelUp() external {
        uint tokenShare = (balanceOf[msg.sender]) / totalSupply;
        uint dinoPower = 0;
        for (uint i = 0; i < userDinosaurs[msg.sender].length; i++) {
            dinoPower += dinosaurs[userDinosaurs[msg.sender][i]].power;
        }
        userLevel[msg.sender] = dinoPower + tokenShare;
        emit LevelUp(msg.sender, userLevel[msg.sender]);
    }
    function getUserDinosaurs(address _user) external view returns (string[] memory) {
        uint[] memory dinoIds = userDinosaurs[_user];
        string[] memory dinoNames = new string[](dinoIds.length);

        for (uint i = 0; i < dinoIds.length; i++) {
            uint dinoId = dinoIds[i];
            dinoNames[i] = dinosaurs[dinoId].name;
        }

        return dinoNames;
    }
    function getLevel(address _user) view  public returns(uint){
         return userLevel[_user];         
    }
    function getAllDinosaurs() external view returns (Dinosaur[] memory) {
        return dinosaurs;
    }
}

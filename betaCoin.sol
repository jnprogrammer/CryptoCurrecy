pragma solidity 0.4.15;

contract Administrate {
    address public admin;

    function administrate() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        if (msg.sender != admin)
        revert();
        _;
    }

    function transferAdmin (address newAdmin) onlyAdmin {
        admin = newAdmin;
    }
}

contract TokenX {
    mapping (address => uint256) public balanceOf;
    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function tokenX (uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) {
        balanceOf[msg.sender] = initialSupply;
        decimal = decimalUnits;
        symbol = tokenSymbol;
        name = tokenName;
    }

    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value)
        revert();
        
        //if receving bal is lower than bal plus receving amount, throw
        if (balanceOf[_to] + _value < balanceOf[_to])
        revert();

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);

    }
}

contract AssetToken is Administrate, TokenX {

    function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) tokenX(0,tokenName,tokenSymbol,decimalUnits) {

    }
}
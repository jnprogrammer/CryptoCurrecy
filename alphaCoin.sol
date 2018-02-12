pragma solidity 0.4.15;

contract MakeAdmin {
    address public adminAddr;
    
    function admin() {
        adminAddr = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != adminAddr)
        revert();
        _;
    }

    function transferAdminPower(address newAddr) onlyAdmin {
        adminAddr = newAddr;
    }
}

contract AlphaCoin {

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256 )) public allowance;
    string public standard = "AlphaCoin v1.0";
    string public name;
    string public symbol;
    uint8 public decimal; //this controls how many decimal places we use when breaking up a single coin
    uint256 public totalSupply; //max coins avalible 

    event Transfer(address indexed from, address indexed to, uint256 value);

    function AlphaCoin (uint256 initSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) {
        balanceOf[msg.sender] = initSupply;
        totalSupply = initSupply;
        decimal = decimalUnits;
        symbol = tokenSymbol;
        name = tokenName;
    }

    function transfer (address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value)
        revert();

        //for security to prevent number roll over 0-255 back to 0
        if (balanceOf[_to] + _value < balanceOf[_to])
        revert();

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender,_to, _value);
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success){
        //1, checks balance of sender is less than sending value
        if (balanceOf[_from] < _value)
        revert();
        // checks if 
        if (balanceOf[_to] + _value < balanceOf[_to])
        revert();
        if (_value > allowance[_from][msg.sender])
        revert();

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
}

contract AlphaCoinAdv is MakeAdmin, AlphaCoin {

    uint256 minimumBalForAccounts = 5 finney;
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;

    event FrozenFund(address target, bool frozen);

    function AlphaCoinAdv(uint256 initSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) AlphaCoin (0, tokenName, tokenSymbol, decimalUnits) {
        totalSupply = initSupply;
        if (centralAdmin != 0)
            adminAddr = centralAdmin;
        else
            adminAddr = msg.sender;
        balanceOf[adminAddr] = initSupply;
        totalSupply = initSupply;
    }

    function mintToken (address target, uint256 mintedAmount) onlyAdmin {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target,mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyAdmin {
        frozenAccount[target] = freeze;
        //I think adding frozenAccount[target] as a arg will work too.
        FrozenFund(target,freeze);
    }

    function transfer (address _to, uint256 _value) {
        if (msg.sender.balance < minimumBalForAccounts)
        sell((minimumBalForAccounts - msg.sender.balance)/sellPrice);

        if (frozenAccount[msg.sender])
        revert();

        if (balanceOf[msg.sender] < _value)
        revert();

        //for security to prevent number roll over 0-255 back to 0
        if (balanceOf[_to] + _value < balanceOf[_to])
        revert();

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender,_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success){
        if (frozenAccount[_from])
        revert();
        //1, checks balance of sender is less than sending value
        if (balanceOf[_from] < _value)
        revert();
        // checks if 
        if (balanceOf[_to] + _value < balanceOf[_to])
        revert();
        if (_value > allowance[_from][msg.sender])
        revert();

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function setPricese(uint256 newSellPrice, uint256 newBuyPrice) onlyAdmin {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint256 amount = (msg.value/(1 ether)) / buyPrice;
        if (balanceOf[this] < amount)
        revert();
        balanceOf[msg.sender] += amount;
        balanceOf[this] -= amount;
        Transfer(this,msg.sender,amount);
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount)
        revert();
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;
        if (!msg.sender.send(amount * sellPrice * 1 ether)) {
             revert();
        } else {
            Transfer(msg.sender,this,amount);
        }
       
    } 

    function giveBlockReward() {
        balanceOf[block.coinbase] += 1;
    }

// Proof of Work code **********
    bytes32 public currentChallenge;
    uint public timeOfLastProof;
    uint public difficulty = 10**32;

    function proofOfWork(uint nonce) {
        bytes8 n = bytes8(sha3(nonce,currentChallenge));

        if (n < bytes8(difficulty)) 
        revert();

        uint timeSinceLastBlock = (now - timeOfLastProof);

        if (timeSinceLastBlock < 5 seconds)
        revert();

        balanceOf[msg.sender] += timeSinceLastBlock / 60 seconds;
        difficulty = difficulty * 10 minutes / timeOfLastProof + 1;
        timeOfLastProof = now;
        currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1));

    }

// ****************************

}
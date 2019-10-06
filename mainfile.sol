pragma solidity ^0.5.0;

contract EAuction{
    
    enum auction{
        running,
        completed
    }
    
    struct Item{
        string name;
        address seller;
        auction status;
    }

    uint startTime = now;
    uint stopTime = startTime + 600;

    modifier canmodify(){
        require(now<=stopTime);
        _;
    }
    
    modifier onlyIfItemExists(uint itemID) {
        require(_items[itemID].seller != address(0), "Item seller does not exist");
        _;
    }
    
    event AddItem(string name, address seller);
    event Bid(string name, address buyer, uint price);
    event ItemPurchased(uint itemID, address buyer, address seller);
    event FundsPulled(address owner, uint amount);  
    
    //seller
    
    Item[] private _items;
    mapping (uint => uint[]) private bid;
    mapping (uint => address[]) private add;
    mapping (address => uint) private _pendingWithdrawals;
    
    //Assume only one user adds an item
    
    function addNewItem(string memory name) public canmodify(){
        _items.push(Item({
            name: name,
            seller: msg.sender,
            status: auction.running
        }));
        

        emit AddItem(name, msg.sender);
        
    }

    //bids
    
    function bids(uint itemID, uint bidprice) public canmodify(){
        bid[itemID].push(bidprice);
        add[itemID].push(msg.sender);
        
        emit Bid(_items[itemID].name,msg.sender,bidprice);
    }
    
    uint maxi = 0;
    function findmaxbid(uint[] memory bidd) private returns(uint){
        uint max = 0;
        for(uint i = 0; i<bidd.length ;i++)
        {
            if(max<bidd[i]){
                max = bidd[i];
                maxi = i;
            }
        }
        if(bidd.length == 0 || max == 0)
        {
            max = 0;
            maxi = 0;
        }
        return max;
    }
    
    function findmaxadd(address[] memory addr) private view returns(address){
        return addr[maxi];
    }
    
    
    uint[] maxprice;
    address[] maxaddress;
    
    function Calculate_max() private {
        for (uint i = 0; i<_items.length ;i++)
        {
            maxprice.push(findmaxbid(bid[i]));
            maxaddress.push(findmaxadd(add[i]));
        }
    }

    function getBidsResult() public view returns(uint[] memory){
        return maxprice;
    }
    
    function getAddResult() public view returns(address[] memory){
        return maxaddress;
    }
    
    function buyItem() public payable { 
        Calculate_max();
        for(uint i = 0; i < _items.length; i++){
            if (maxprice[i] == 0)
            {
                continue;
            }
            require(msg.sender == maxaddress[i] , "Only Highest bidder can buy the item!");
            Item storage currentItem = _items[i];
            require(currentItem.status == auction.running, "Item is not available");
            currentItem.status = auction.completed;
            _pendingWithdrawals[currentItem.seller] = maxprice[i];
            emit ItemPurchased(i, maxaddress[i], currentItem.seller);
        }        
    }
    
    function pullFunds() public returns (bool) {
        require(_pendingWithdrawals[msg.sender] > 0, "No pending withdrawals");

        uint outstandingFundsAmount = _pendingWithdrawals[msg.sender];

        if (msg.sender.send(outstandingFundsAmount)) {
            emit FundsPulled(msg.sender, outstandingFundsAmount);
            return true;
        } else {
            return false;
        }
    }
}

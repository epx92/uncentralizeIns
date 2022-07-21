pragma solidity ^0.8.13;

//ierc20
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
//safemath

struct paymentHistory{
    uint256 pymtamt;
    uint40 time;
    }

struct invHist{
    address contyaddy;
    uint256 amtInv;
}

struct Insurer{
    address [] referrals;
    uint256 refRewards;
    uint256 tier;
    uint40 startTime;
    //uint256 monthsAlive;
    uint256 withdrawable;
    bool isCurrent;
    uint256 count1;
    uint256 count2;
    //uint256 testWallet;
    uint256 userPool;
    paymentHistory [] payments;
    invHist [] invCons;
}

struct contractInfo{
    address contractAddress;
    uint40 contCreation;
    bool covered;
    address [] recipients;
}

struct voterInfo{
    address contAddress;
    uint40 dateOfCreation;
    uint8 vote1;
    uint8 vote2;
    uint8 vote3;
    address voter1;
    address voter2;
    address voter3;
    //uint256 testvalue;
}

struct main{
    address [] ruggedList;
    contractInfo [] coveredContracts;
    voterInfo [] voterList;
}

contract unCentralize{
    using SafeMath for uint256;
    using SafeMath for uint40;

    uint256 centralPool;
    uint256 payoutTiers;
    uint256 constant public tierOne = 50;
    uint256 constant public tierTwo = 150;
    uint256 constant public tierThree = 300;
    uint256 constant public percentDivider = 1000;
    uint256 constant public twoDivider = 2;
    uint256 constant public threeDivider = 3;
    uint256 constant public five = 5;
    uint256 constant public ten = 10;
    uint256 constant public twenty = 20;
    address [] ruggedList;
    contractInfo [] coveredContracts;
    voterInfo [] voterList;

    mapping(address => Insurer) public insurers; // look at this variable after
    mapping(address => uint256) public indVoteCount;

    address payable public devWallet;

    constructor(address payable devAddress){    
        devWallet = devAddress;
    }

    function refPayout(address refAddy, uint256 refPymt) private {
        Insurer storage insurer = insurers[refAddy];
        if (refPymt == tierOne){
            insurer.refRewards += five;
        }
        if (refPymt == tierTwo){
            insurer.refRewards += ten;
        }
        if (refPymt == tierThree){
            insurer.refRewards += twenty;
        }
}

    function signUp (address referral, uint256 pymt, uint256 tierChosen) public {
        Insurer storage insurer = insurers[msg.sender];
        //take payment
        require(insurer.payments.length < 1, "You've already signed up!");
        require(pymt == tierChosen, "Payment amount and tier does not match");
        insurer.payments.push(paymentHistory({
            pymtamt: pymt,
            time: uint40(block.timestamp)
        }));
        refPayout(referral,pymt);
        insurer.tier = tierChosen;
        insurer.startTime = uint40(block.timestamp);
        centralPool += pymt;
        insurer.userPool += pymt;
        
    }

    function checkIfCurrent (address addry) internal view {
        Insurer storage insurer = insurers[addry];
        // require(insurer.payments.length > 1); //how many months can they start withdrawing at

        for (uint256 i = 0; i < insurer.payments.length; i++ ){
            for (uint256 y = 1; y < insurer.payments.length; i++){
            uint40 iterPayments = insurer.payments[i].time; //might have to become state/storage variable?
            uint40 iterPayments2 = insurer.payments[y].time; // "" ""
            require (iterPayments < (iterPayments2 - twoDivider), "You are not current!"); //fix 40 day variable later
            }
        }

    }

    function makePayment() public{
        Insurer storage insurer = insurers[msg.sender];
        require (insurer.payments.length > 0, "You have not signed up!");
        //busd.transfer
        uint256 theTier = insurer.tier;
        
        insurer.payments.push(paymentHistory({
            pymtamt: theTier,
            time: uint40(block.timestamp)
        }));
    
        centralPool += theTier;
        insurer.userPool += theTier;

    }

    // function fetchAddyinfo(address adddy) public returns(uint40 cc, bool cvered, uint256 lngth )  {
    //     for (uint i = 0; i < coveredContracts.length; i++)
    //         if (coveredContracts[i].contractAddress = adddy){
    //             return coveredContracts[i].contCreation;
    //             return coveredContracts[i].covered;
    //             return coveredContracts.recipients.length;
    //         }
    // }           

    function claimPayout() public {
        Insurer storage insurer = insurers[msg.sender];
        checkIfCurrent(msg.sender);
        if (insurer.withdrawable > 0 || insurer.refRewards > 0){
            insurer.withdrawable +=1;
            //uint256 theAmt = withdrawable + refRewards
            //BUSD.transfer(msg.sender, theAmt)
        }
    }

    function addNewContract(address contAddy, uint256 invAmt) public {
        Insurer storage insurer = insurers[msg.sender];
        checkIfCurrent(msg.sender);
        for (uint i = 0; i < coveredContracts.length; i++){
            if (coveredContracts[i].contractAddress == contAddy){
                for (uint256 z = 0; z < coveredContracts[i].recipients.length; z++){
                    if (coveredContracts[i].recipients[z] != msg.sender){
                        coveredContracts[i].recipients.push(msg.sender);}}
                for (uint256 y = 0; y < insurer.invCons.length; y++){
                        address t = insurer.invCons[y].contyaddy;
                            if (t == contAddy){
                                break;
                            }
                            else {
                                insurer.invCons.push(invHist({
                                    contyaddy: contAddy,
                                    amtInv: invAmt
                                }));

                            }
                }
            }       
        }
    } 

    function makeClaim(address theStar, uint40 creation) external{
        nominate(theStar, creation);
    }


    function nominate(address star, uint40 creatDat) internal {
        for (uint i = 0; i < voterList.length; i++){
            if (voterList[i].contAddress == star)
                break;
        }
        
    voterList.push(voterInfo({
        contAddress: star,
        dateOfCreation: creatDat,
        vote1: 0,
        vote2: 0,
        vote3: 0,
        voter1: 0x0000000000000000000000000000000000000000,
        voter2: 0x0000000000000000000000000000000000000000,
        voter3: 0x0000000000000000000000000000000000000000
    }));
    }


    function vote(uint8 voterChoice) public {
        for (uint i = 0; i < voterList.length; i++){
            if (voterList[i].vote1 == 0){
                if (voterList[i].voter1 != msg.sender && voterList[i].voter2 != msg.sender && voterList[i].voter3 != msg.sender){
                    voterList[i].vote1 = voterChoice;
                    voterList[i].voter1 = msg.sender;
                    break;
                    }
                }
                if (voterList[i].vote2 == 0){
                    if (voterList[i].voter1 != msg.sender && voterList[i].voter2 != msg.sender && voterList[i].voter3 != msg.sender){
                        voterList[i].vote2 = voterChoice;
                        voterList[i].voter2 = msg.sender;
                        break;
                    }
                }
                if (voterList[i].vote3 == 0){
                    if (voterList[i].voter1 != msg.sender && voterList[i].voter2 != msg.sender && voterList[i].voter3 != msg.sender){
                        voterList[i].vote3 = voterChoice;
                        voterList[i].voter3 = msg.sender;
                        break;
                    }
                }
        }    

        for (uint y = 0; y < voterList.length; y++){
            if (voterList[y].vote1 > 0 && voterList[y].vote2 > 0 && voterList[y].vote3 > 0){
                uint256 randVar = voterList[y].vote1 + voterList[y].vote2 + voterList[y].vote1;
                //check if you can add three
                if (randVar > 4) {
                    coveredContracts[y].covered = true;
                    address[] storage transitionVar = coveredContracts[y].recipients;
                    for (uint256 z = 0; z < transitionVar.length; z++){
                        address plHolder = transitionVar[z];
                        calc(plHolder);   
                        }
                    }
                }
            }
        }

    // function voteToAdd(){

    // }


    function calc(address thatAddress) internal {
        Insurer storage insurer = insurers[thatAddress];
        for (uint256 d = 0; d < insurer.invCons.length; d++){
            address randomAddry = insurer.invCons[d].contyaddy;
            if (randomAddry == thatAddress){
                for (uint256 x = 0; x < insurer.invCons.length; x++){
                    uint256 threshhold1 = address(this).balance.mul(five).div(percentDivider);
                    uint256 threshhold2 = address(this).balance.mul(ten).div(percentDivider);
                    uint256 threshhold3 = address(this).balance.mul(twenty).div(percentDivider);
                    uint256 payoutAmt = insurer.invCons[d].amtInv;
                        if (payoutAmt < threshhold1){
                        insurer.withdrawable += payoutAmt;
                        break;
                        }
                        if (payoutAmt < threshhold2){
                        insurer.withdrawable += payoutAmt.div(twoDivider);
                        break;
                        } 
                        if (payoutAmt < threshhold3){
                        insurer.withdrawable += payoutAmt.div(threeDivider);
                        break;
                        }
                }
            }
        }
    }
}

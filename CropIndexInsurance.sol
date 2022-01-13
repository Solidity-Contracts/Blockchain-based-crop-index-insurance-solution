pragma solidity =0.4.25;

contract Registration {
    

    address private owner;
    mapping(address=>bool) public farmer;
    mapping(address=>bool) public insurance_provider;
    mapping(address=>bool) public weather_provider;

    event FarmerRegistered(address farmer);
    event Insurance_providerRegistered(address insurance_provider);
    event Weather_providerRegistered(address weather_provider);

    
    constructor() public{
        owner=msg.sender;
    }
    
    function registerFarmer() public{
        require(!farmer[msg.sender] && !insurance_provider[msg.sender] && !weather_provider[msg.sender],
        "Address already used");
        
        farmer[msg.sender]=true;
        emit FarmerRegistered(msg.sender);
    }
    
    function registerInsurance_provider() public{
         require(!farmer[msg.sender] && !insurance_provider[msg.sender] && !weather_provider[msg.sender],
        "Address already used");
        
        insurance_provider[msg.sender]=true;
        emit Insurance_providerRegistered(msg.sender);
    }

        function registerWeather_provider() public{
         require(!farmer[msg.sender] && !insurance_provider[msg.sender] && !weather_provider[msg.sender],
        "Address already used");
        
        weather_provider[msg.sender]=true;
        emit Weather_providerRegistered(msg.sender);
    }
    
    function FarmerExists(address s) view public returns (bool) {
        return farmer[s];
    }
    
    function InsuranceProviderExists(address r) view public returns (bool) {
        return insurance_provider[r];
    }

    function WeatherProviderExists(address t) view public returns (bool) {
        return weather_provider[t];
    }
}
contract InsurancePolicy{
    
    struct insurance_type{
        uint insurance_premium;
        uint insurance_period;
        uint agreed_payout_amount;
        uint agreed_index_level;
    }

    Registration registrationContract;
    mapping(uint=>insurance_type) insurance;
    address owner;

    event NewInsurancePolicyAdded(uint policy_number, uint insurance_premium, uint insurance_period, uint agreed_payout_amount, uint agreed_index_level);
    event InsuranceAgreed(string, uint, uint);

    modifier onlyOwner{
        require(msg.sender==owner,
        "Sender not authorized."
        );
        _;
    } 

         modifier onlyFarmer{
        require(registrationContract.FarmerExists(msg.sender),
        "Sender not authorized."
        );
        _;
     }  

    constructor(address registrationAddress)public {
        registrationContract=Registration(registrationAddress);
        
        require (registrationContract.InsuranceProviderExists(msg.sender),
        "The sender is not an approved insurance provider");

        owner=msg.sender;
    }

     function addInsurancePolicy(uint policy_number, uint insurance_premium, uint insurance_period, uint agreed_payout_amount, uint agreed_index_level) public onlyOwner{
         if(insurance_premium!=0){
        insurance[policy_number].insurance_premium = insurance_premium;
        }
        insurance[policy_number].insurance_period = now + (insurance_period * 1 days);
        insurance[policy_number].agreed_payout_amount = agreed_payout_amount;
        insurance[policy_number].agreed_index_level = agreed_index_level;
        
        emit NewInsurancePolicyAdded(policy_number, insurance[policy_number].insurance_premium,insurance[policy_number].insurance_period,insurance[policy_number].agreed_payout_amount,insurance[policy_number].agreed_index_level);
     }

     function isOwner(address o) view public returns (bool){
        return(o==msg.sender);
     }

     function InsurancePeriod (uint policy_number)  view public returns(uint){
     return(insurance[policy_number].insurance_period);
     }

     function InsurancePayOut (uint policy_number)  view public returns(uint){
     return(insurance[policy_number].agreed_payout_amount);
     }

     function AgreedIndexLevel (uint policy_number)  view public returns(uint){
     return(insurance[policy_number].agreed_index_level);
     }

    function payInsurancePremium(bool farmerDecision, uint policy_number, address insurance_provider) public onlyFarmer payable{
       
       require (farmerDecision == true, "Farmer does not agree with the terms & conditions stated in the policy");
       require(msg.value == insurance[policy_number].insurance_premium);

       emit InsuranceAgreed ("Farmer agreed to the insurance provider's new insurance policy with policy number and agreed premium equal to", policy_number,insurance[policy_number].insurance_premium);
      
       if (registrationContract.InsuranceProviderExists(insurance_provider) == true){
          insurance_provider.transfer(msg.value);
       }
    }  

     function getBalance(address desired_address) public view returns(uint balance) {
        return address(desired_address).balance;
    }
}

contract WeatherVerification{

     struct weather_info{
        uint index_level; 
     }
     
     Registration registrationContract;
     InsurancePolicy insuranceContract;
     
     mapping(uint=>weather_info) weather;
     address owner;

     event WeatherUpdate(uint policy_number, uint index_level);
    
     modifier onlyOwner{
        require(msg.sender==owner,
        "Sender not authorized."
        );
        _;
     }  
    
     modifier onlyWeatherProvider{
        require(registrationContract.WeatherProviderExists(msg.sender),
        "Sender not authorized."
        );
        _;
     }  

     constructor(address registrationAddress,address insuranceAddress)public {
        registrationContract=Registration(registrationAddress);
        insuranceContract=InsurancePolicy(insuranceAddress);
        owner=msg.sender;
     } 

     function reportWeatherStatus( uint policy_number, uint index_level) public onlyWeatherProvider{    
      uint insurance_period = insuranceContract.InsurancePeriod(policy_number);
      
      if ( now < insurance_period){
      weather[policy_number].index_level = index_level;
      }
     emit WeatherUpdate(policy_number,weather[policy_number].index_level);
     }

     function IndexLevel (uint policy_number)  view public returns(uint){
     return(weather[policy_number].index_level);
     }
}

contract RollPayout{


     Registration registrationContract;
     InsurancePolicy insuranceContract;
     WeatherVerification weatherContract;

      //mapping(uint=>RollPayout) payout;
      address owner;
      event PayoutIssued(string , address, uint);

      modifier onlyOwner{
        require(msg.sender==owner,
        "Sender not authorized."
        );
        _;
    }  

     constructor(address registrationAddress, address insuranceAddress, address weatherAddress)public {
        registrationContract=Registration(registrationAddress);
        insuranceContract=InsurancePolicy(insuranceAddress);
        weatherContract=WeatherVerification(weatherAddress);
        
        require (registrationContract.InsuranceProviderExists(msg.sender),
        "The sender is not an approved insurance provider");

        owner=msg.sender;
    }

    function IssuePayout(uint policy_number, address farmer) public onlyOwner payable{
       
    
        require(weatherContract.IndexLevel(policy_number)>= insuranceContract.AgreedIndexLevel(policy_number), "The index level detected is below the agreed index stated in the insurance policy");
        require(msg.value == insuranceContract.InsurancePayOut(policy_number));
       
        emit PayoutIssued ("Payout has been issued to farmer with address and payout equal to", farmer ,insuranceContract.InsurancePayOut(policy_number) );
      
       if (registrationContract.FarmerExists(farmer) == true){
          farmer.transfer(msg.value);
       }
       
    }  

     function getBalance(address desired_address) public view returns(uint balance) {
        return address(desired_address).balance;
    }


}

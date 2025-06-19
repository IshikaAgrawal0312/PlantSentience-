// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PlantSentience
 * @dev Smart contract for tracking plant health and growth using IoT sensors
 * @author PlantSentience Team
 */
contract PlantSentience {
    
    // Struct to store plant data
    struct Plant {
        uint256 id;
        string name;
        string species;
        address owner;
        uint256 registrationTime;
        bool isActive;
        uint256 lastUpdateTime;
        PlantHealth currentHealth;
    }
    
    // Struct to store plant health metrics
    struct PlantHealth {
        uint256 soilMoisture;     // Percentage (0-100)
        uint256 temperature;      // Celsius * 100 (for precision)
        uint256 lightIntensity;   // Lux
        uint256 humidity;         // Percentage (0-100)
        uint256 phLevel;          // pH * 100 (for precision)
        uint256 timestamp;
    }
    
    // Events
    event PlantRegistered(uint256 indexed plantId, string name, address indexed owner);
    event HealthDataUpdated(uint256 indexed plantId, uint256 timestamp);
    event PlantTransferred(uint256 indexed plantId, address indexed from, address indexed to);
    event AlertTriggered(uint256 indexed plantId, string alertType, string message);
    
    // State variables
    mapping(uint256 => Plant) public plants;
    mapping(uint256 => PlantHealth[]) public healthHistory;
    mapping(address => uint256[]) public ownerPlants;
    
    uint256 public nextPlantId;
    uint256 public totalPlants;
    
    // Health thresholds for alerts
    uint256 public constant MIN_SOIL_MOISTURE = 30;
    uint256 public constant MAX_SOIL_MOISTURE = 70;
    uint256 public constant MIN_TEMPERATURE = 1500; // 15°C
    uint256 public constant MAX_TEMPERATURE = 3000; // 30°C
    uint256 public constant MIN_HUMIDITY = 40;
    uint256 public constant MAX_HUMIDITY = 80;
    
    // Modifiers
    modifier onlyPlantOwner(uint256 _plantId) {
        require(plants[_plantId].owner == msg.sender, "Not the plant owner");
        _;
    }
    
    modifier plantExists(uint256 _plantId) {
        require(plants[_plantId].id != 0, "Plant does not exist");
        _;
    }
    
    modifier validHealthData(PlantHealth memory _health) {
        require(_health.soilMoisture <= 100, "Invalid soil moisture");
        require(_health.humidity <= 100, "Invalid humidity");
        require(_health.phLevel >= 400 && _health.phLevel <= 1000, "Invalid pH level"); // pH 4.0 to 10.0
        _;
    }
    
    /**
     * @dev Register a new plant in the system
     * @param _name Name of the plant
     * @param _species Species of the plant
     * @return plantId The ID of the newly registered plant
     */
    function registerPlant(
        string memory _name,
        string memory _species
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "Plant name cannot be empty");
        require(bytes(_species).length > 0, "Plant species cannot be empty");
        
        uint256 plantId = nextPlantId++;
        
        plants[plantId] = Plant({
            id: plantId,
            name: _name,
            species: _species,
            owner: msg.sender,
            registrationTime: block.timestamp,
            isActive: true,
            lastUpdateTime: 0,
            currentHealth: PlantHealth(0, 0, 0, 0, 0, 0)
        });
        
        ownerPlants[msg.sender].push(plantId);
        totalPlants++;
        
        emit PlantRegistered(plantId, _name, msg.sender);
        return plantId;
    }
    
    /**
     * @dev Update plant health data from IoT sensors
     * @param _plantId ID of the plant
     * @param _soilMoisture Soil moisture percentage
     * @param _temperature Temperature in Celsius * 100
     * @param _lightIntensity Light intensity in Lux
     * @param _humidity Humidity percentage
     * @param _phLevel pH level * 100
     */
    function updatePlantHealth(
        uint256 _plantId,
        uint256 _soilMoisture,
        uint256 _temperature,
        uint256 _lightIntensity,
        uint256 _humidity,
        uint256 _phLevel
    ) external onlyPlantOwner(_plantId) plantExists(_plantId) {
        
        PlantHealth memory newHealth = PlantHealth({
            soilMoisture: _soilMoisture,
            temperature: _temperature,
            lightIntensity: _lightIntensity,
            humidity: _humidity,
            phLevel: _phLevel,
            timestamp: block.timestamp
        });
        
        // Validate health data
        require(newHealth.soilMoisture <= 100, "Invalid soil moisture");
        require(newHealth.humidity <= 100, "Invalid humidity");
        require(newHealth.phLevel >= 400 && newHealth.phLevel <= 1000, "Invalid pH level");
        
        // Update current health
        plants[_plantId].currentHealth = newHealth;
        plants[_plantId].lastUpdateTime = block.timestamp;
        
        // Store in history
        healthHistory[_plantId].push(newHealth);
        
        // Check for alerts
        _checkHealthAlerts(_plantId, newHealth);
        
        emit HealthDataUpdated(_plantId, block.timestamp);
    }
    
    /**
     * @dev Get comprehensive plant analytics and health score
     * @param _plantId ID of the plant
     * @return healthScore Overall health score (0-100)
     * @return totalReadings Total number of health readings
     * @return avgSoilMoisture Average soil moisture over last 7 days
     * @return avgTemperature Average temperature over last 7 days
     * @return daysActive Number of days since registration
     */
    function getPlantAnalytics(uint256 _plantId) 
        external 
        view 
        plantExists(_plantId) 
        returns (
            uint256 healthScore,
            uint256 totalReadings,
            uint256 avgSoilMoisture,
            uint256 avgTemperature,
            uint256 daysActive
        ) 
    {
        Plant memory plant = plants[_plantId];
        PlantHealth[] memory history = healthHistory[_plantId];
        
        totalReadings = history.length;
        daysActive = (block.timestamp - plant.registrationTime) / 86400; // Convert to days
        
        if (totalReadings == 0) {
            return (0, 0, 0, 0, daysActive);
        }
        
        // Calculate averages for last 7 days
        uint256 weekAgo = block.timestamp - 604800; // 7 days in seconds
        uint256 recentReadings = 0;
        uint256 totalMoisture = 0;
        uint256 totalTemp = 0;
        
        for (uint256 i = 0; i < history.length; i++) {
            if (history[i].timestamp >= weekAgo) {
                totalMoisture += history[i].soilMoisture;
                totalTemp += history[i].temperature;
                recentReadings++;
            }
        }
        
        if (recentReadings > 0) {
            avgSoilMoisture = totalMoisture / recentReadings;
            avgTemperature = totalTemp / recentReadings;
        }
        
        // Calculate health score based on current readings
        healthScore = _calculateHealthScore(plant.currentHealth);
    }
    
    /**
     * @dev Transfer plant ownership
     * @param _plantId ID of the plant
     * @param _newOwner Address of the new owner
     */
    function transferPlant(uint256 _plantId, address _newOwner) 
        external 
        onlyPlantOwner(_plantId) 
        plantExists(_plantId) 
    {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        address oldOwner = plants[_plantId].owner;
        plants[_plantId].owner = _newOwner;
        
        // Remove from old owner's list
        _removeFromOwnerList(oldOwner, _plantId);
        
        // Add to new owner's list
        ownerPlants[_newOwner].push(_plantId);
        
        emit PlantTransferred(_plantId, oldOwner, _newOwner);
    }
    
    // Internal helper functions
    function _calculateHealthScore(PlantHealth memory _health) internal pure returns (uint256) {
        if (_health.timestamp == 0) return 0;
        
        uint256 score = 100;
        
        // Soil moisture scoring
        if (_health.soilMoisture < MIN_SOIL_MOISTURE || _health.soilMoisture > MAX_SOIL_MOISTURE) {
            score -= 20;
        }
        
        // Temperature scoring
        if (_health.temperature < MIN_TEMPERATURE || _health.temperature > MAX_TEMPERATURE) {
            score -= 20;
        }
        
        // Humidity scoring
        if (_health.humidity < MIN_HUMIDITY || _health.humidity > MAX_HUMIDITY) {
            score -= 15;
        }
        
        // pH scoring (optimal range 6.0-7.0)
        if (_health.phLevel < 600 || _health.phLevel > 700) {
            score -= 15;
        }
        
        // Light intensity scoring (basic check)
        if (_health.lightIntensity < 1000) { // Minimum 1000 lux
            score -= 10;
        }
        
        return score;
    }
    
    function _checkHealthAlerts(uint256 _plantId, PlantHealth memory _health) internal {
        // Soil moisture alerts
        if (_health.soilMoisture < MIN_SOIL_MOISTURE) {
            emit AlertTriggered(_plantId, "LOW_SOIL_MOISTURE", "Soil moisture is too low - watering needed");
        } else if (_health.soilMoisture > MAX_SOIL_MOISTURE) {
            emit AlertTriggered(_plantId, "HIGH_SOIL_MOISTURE", "Soil moisture is too high - reduce watering");
        }
        
        // Temperature alerts
        if (_health.temperature < MIN_TEMPERATURE) {
            emit AlertTriggered(_plantId, "LOW_TEMPERATURE", "Temperature is too low for optimal growth");
        } else if (_health.temperature > MAX_TEMPERATURE) {
            emit AlertTriggered(_plantId, "HIGH_TEMPERATURE", "Temperature is too high - provide shade or cooling");
        }
        
        // Humidity alerts
        if (_health.humidity < MIN_HUMIDITY) {
            emit AlertTriggered(_plantId, "LOW_HUMIDITY", "Humidity is too low - increase moisture in air");
        } else if (_health.humidity > MAX_HUMIDITY) {
            emit AlertTriggered(_plantId, "HIGH_HUMIDITY", "Humidity is too high - improve ventilation");
        }
    }
    
    function _removeFromOwnerList(address _owner, uint256 _plantId) internal {
        uint256[] storage plantList = ownerPlants[_owner];
        for (uint256 i = 0; i < plantList.length; i++) {
            if (plantList[i] == _plantId) {
                plantList[i] = plantList[plantList.length - 1];
                plantList.pop();
                break;
            }
        }
    }
    
    // View functions
    function getPlantsByOwner(address _owner) external view returns (uint256[] memory) {
        return ownerPlants[_owner];
    }
    
    function getPlantHealthHistory(uint256 _plantId, uint256 _limit) 
        external 
        view 
        plantExists(_plantId) 
        returns (PlantHealth[] memory) 
    {
        PlantHealth[] memory history = healthHistory[_plantId];
        uint256 length = history.length;
        
        if (_limit == 0 || _limit > length) {
            _limit = length;
        }
        
        PlantHealth[] memory result = new PlantHealth[](_limit);
        uint256 startIndex = length - _limit;
        
        for (uint256 i = 0; i < _limit; i++) {
            result[i] = history[startIndex + i];
        }
        
        return result;
    }
}

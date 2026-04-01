# 🐺 LXR-RANCH — Events Reference

> **The Land of Wolves** | **The Lux Empire**
> Version 1.0.0

---

## Client Events

| Event | Direction | Parameters | Description |
|-------|-----------|------------|-------------|
| `lxr-ranch:client:openranch` | Server → Client | ranchid, jobaccess | Open ranch menu |
| `lxr-ranch:client:spawnAnimals` | Server → Client | animals (table) | Spawn animal entities |
| `lxr-ranch:client:removeAnimal` | Server → Client | animalid | Remove animal entity |
| `lxr-ranch:client:refreshSingleAnimal` | Server → Client | animalid, data | Update single animal data |
| `lxr-ranch:client:spawnAnimalGranted` | Server → Client | animalId, animalData | Spawn permission granted |
| `lxr-ranch:client:spawnAnimalDenied` | Server → Client | animalId, reason | Spawn permission denied |
| `lxr-ranch:client:openAnimalOverview` | Client | ranchid | Open animal overview menu |
| `lxr-ranch:client:openStaffManagement` | Client | ranchid | Open staff management menu |
| `lxr-ranch:client:openHerdingMenu` | Client | — | Open herding menu |
| `lxr-ranch:client:opentraineemenu` | Client | ranchid | Open trainee menu |
| `lxr-ranch:client:openranchhandmenu` | Client | ranchid | Open ranch hand menu |
| `lxr-ranch:client:openmanagermenu` | Client | ranchid | Open manager menu |

## Server Events

| Event | Direction | Parameters | Description |
|-------|-----------|------------|-------------|
| `lxr-ranch:server:feedAnimal` | Client → Server | data (animalid) | Feed an animal |
| `lxr-ranch:server:waterAnimal` | Client → Server | data (animalid) | Water an animal |
| `lxr-ranch:server:collectProduct` | Client → Server | data (animalid) | Collect production |
| `lxr-ranch:server:buyAnimal` | Client → Server | purchaseData | Purchase livestock |
| `lxr-ranch:server:sellAnimal` | Client → Server | animalid, salePrice, coords | Sell single animal |
| `lxr-ranch:server:sellAllAnimals` | Client → Server | animals, coords | Sell multiple animals |
| `lxr-ranch:server:startBreeding` | Client → Server | animal1id, animal2id | Initiate breeding |
| `lxr-ranch:server:ranchstorage` | Client → Server | data (ranchid) | Open ranch storage |
| `lxr-ranch:server:fillWaterBucket` | Client → Server | — | Refill water bucket |
| `lxr-ranch:server:requestAnimalSpawn` | Client → Server | animalId, animalData | Request spawn permission |
| `lxr-ranch:server:reportDespawn` | Client → Server | animalId | Report animal despawn |
| `lxr-ranch:server:saveAnimalPosition` | Client → Server | animalid, x, y, z, w | Save position |
| `lxr-ranch:server:hireEmployee` | Client → Server | ranchid, targetId, grade | Hire staff |
| `lxr-ranch:server:fireEmployee` | Client → Server | ranchid, citizenid | Fire staff |
| `lxr-ranch:server:promoteEmployee` | Client → Server | ranchid, citizenid | Promote staff |
| `lxr-ranch:server:demoteEmployee` | Client → Server | ranchid, citizenid | Demote staff |
| `lxr-ranch:server:payTax` | Client → Server | ranchid | Pay ranch tax |
| `lxr-ranch:server:refreshAnimals` | Client → Server | — | Request animal data refresh |

## Server Callbacks

| Callback | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `lxr-ranch:server:countanimals` | ranchid | number | Count animals at ranch |
| `lxr-ranch:server:getAnimalOverview` | ranchid | overview data | Get animal overview |
| `lxr-ranch:server:getBreedingStatus` | animalid | status data | Get breeding readiness |
| `lxr-ranch:server:getPregnancyProgress` | animalid | progress data | Get pregnancy progress |
| `lxr-ranch:server:getAvailableAnimalsForBreeding` | ranchid, animalid | animals table | Get breeding partners |
| `lxr-ranch:server:getNearbyAnimalsForSale` | ranchid, coords | animals table | Get sellable animals |
| `lxr-ranch:server:getAnimalProductionStatus` | animalid | production data | Get production status |
| `lxr-ranch:server:getStaffList` | ranchid | staff data | Get employees |
| `lxr-ranch:server:getNearbyPlayers` | — | players table | Get nearby players |
| `lxr-ranch:server:getDashboardData` | ranchid | dashboard data | Get NUI dashboard data |

---

**🐺 wolves.land — The Land of Wolves**
**© 2026 iBoss21 / The Lux Empire — All Rights Reserved**

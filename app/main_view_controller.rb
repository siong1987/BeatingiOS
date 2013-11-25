class MainViewController < UITableViewController
  attr_accessor :manager
  attr_accessor :peripherals

  def init
    super.tap do |i|
      i.manager     = CBPeripheralManager.alloc.initWithDelegate self, queue:nil
      i.peripherals = []
    end

    self
  end
  
  def viewDidLoad
    super

    self.title = "Bluetooth LE"
  end
  
  def advertiseANCS
    # define the ANCS Characteristics
    notificationSourceUUID = CBUUID.UUIDWithString("9FBF120D-6301-42D9-8C58-25E699A21DBD")
    notificationSource = CBMutableCharacteristic.alloc.initWithType notificationSourceUUID, properties:CBCharacteristicPropertyNotifyEncryptionRequired, value:nil, permissions:CBAttributePermissionsReadEncryptionRequired

    controlPointUUID = CBUUID.UUIDWithString("69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9")
    controlPoint = CBMutableCharacteristic.alloc.initWithType controlPointUUID, properties:CBCharacteristicPropertyWrite, value:nil, permissions:CBAttributePermissionsWriteEncryptionRequired

    dataSourceUUID = CBUUID.UUIDWithString("22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB")
    dataSource = CBMutableCharacteristic.alloc.initWithType dataSourceUUID, properties:CBCharacteristicPropertyNotifyEncryptionRequired, value:nil, permissions:CBAttributePermissionsReadEncryptionRequired

    # define the ANCS Service
    ancsUUID = CBUUID.UUIDWithString("7905F431-B5CE-4E99-A40F-4B1E122D00D0")
    ancs = CBMutableService.alloc.initWithType ancsUUID, primary:true
    ancs.characteristics = [notificationSource, controlPoint, dataSource]

    # define the Advertisement data
    advertisementData = {
      CBAdvertisementDataLocalNameKey: "ANCS",
      CBAdvertisementDataServiceUUIDsKey: [ancsUUID]
    }

    # publish the ANCS service
    manager.addService(ancs)
    manager.startAdvertising(advertisementData)
  end

  # UITableView Data Source
  def numberOfSectionsInTableView(tableview)
    1
  end

  def tableView(tableview, numberOfRowsInSection:section)
    peripherals.count
  end

  CELL_IDENTIFIER = "Cell Identifier"
  def tableView(tableview, cellForRowAtIndexPath:indexPath)
    peripheral = peripherals[indexPath.row]

    cell = tableview.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) || begin
      r = UITableViewCell.alloc.initWithStyle UITableViewCellStyleSubtitle, reuseIdentifier:CELL_IDENTIFIER
      r
    end

    cell.textLabel.text = peripheral.name
    cell.detailTextLabel.text = CFUUIDCreateString(nil, peripheral.UUID)
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator

    cell
  end

  def tableView(tableview, didSelectRowAtIndexPath:indexPath)
    tableview.deselectRowAtIndexPath(indexPath, animated:true)
    
    peripheral = peripherals[indexPath.row]
    peripheral_vc = PeripheralViewController.alloc.initWithPeripheral(peripheral)
    navigationController.pushViewController peripheral_vc, animated:true

    self.stopButtonClicked nil
  end

  # CBPeripheralManagerDelegate
  def peripheralManagerDidUpdateState(peripheral)
    case peripheral.state
    when CBPeripheralManagerStatePoweredOn
      NSLog("peripheralStateChange: Powered On")
      advertiseANCS
    when CBPeripheralManagerStatePoweredOff
      NSLog("peripheralStateChange: Powered Off")
    when CBPeripheralManagerStateResetting
      NSLog("peripheralStateChange: Resetting")
    when CBPeripheralManagerStateUnauthorized
      NSLog("peripheralStateChange: Deauthorized")
    when CBPeripheralManagerStateUnsupported
      NSLog("peripheralStateChange: Unsupported")
    when CBPeripheralManagerStateUnknown
      NSLog("peripheralStateChange: Unknown")
    end
  end

end


inherited FSViewForm: TFSViewForm
  Caption = 'File system View'
  ClientHeight = 452
  ClientWidth = 511
  Position = poScreenCenter
  ExplicitWidth = 519
  ExplicitHeight = 479
  PixelsPerInch = 96
  TextHeight = 13
  object Background: TSpTBXPanel
    Left = 0
    Top = 0
    Width = 511
    Height = 452
    Caption = 'Background'
    Align = alClient
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    TabOrder = 0
    Borders = False
    TBXStyleBackground = True
    ExplicitTop = -1
    ExplicitWidth = 421
    ExplicitHeight = 462
    object SpTBXGroupBox1: TSpTBXGroupBox
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 501
      Height = 188
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 10
      Caption = 'Select a file system'
      Align = alTop
      Padding.Left = 10
      Padding.Top = 10
      Padding.Right = 10
      Padding.Bottom = 10
      TabOrder = 0
      ExplicitWidth = 612
      object SpTBXDock1: TSpTBXDock
        Left = 12
        Top = 150
        Width = 477
        Height = 26
        AllowDrag = False
        Position = dpBottom
        ExplicitTop = 139
        ExplicitWidth = 598
        object SpTBXToolbar1: TSpTBXToolbar
          Left = 0
          Top = 0
          Align = alBottom
          DockPos = 40
          FullSize = True
          Images = ResourcesForm.Images16x16
          Resizable = False
          ShrinkMode = tbsmNone
          Stretch = True
          TabOrder = 0
          Caption = 'SpTBXToolbar1'
          object SpTBXRightAlignSpacerItem1: TSpTBXRightAlignSpacerItem
            CustomWidth = 248
          end
          object SpTBXItem3: TSpTBXItem
            Action = Add
            DisplayMode = nbdmImageAndText
          end
          object SpTBXItem4: TSpTBXItem
            Action = Remove
            DisplayMode = nbdmImageAndText
          end
          object SpTBXSeparatorItem2: TSpTBXSeparatorItem
          end
          object SpTBXItem5: TSpTBXItem
            Action = Edit
            DisplayMode = nbdmImageAndText
          end
          object SpTBXItem1: TSpTBXItem
            Action = Update
            DisplayMode = nbdmImageAndText
          end
        end
      end
      object FilesystemList: TVirtualStringTree
        Left = 12
        Top = 25
        Width = 477
        Height = 125
        Align = alClient
        DragMode = dmAutomatic
        DragOperations = [doMove]
        EditDelay = 300
        Header.AutoSizeIndex = -1
        Header.DefaultHeight = 17
        Header.Font.Charset = DEFAULT_CHARSET
        Header.Font.Color = clWindowText
        Header.Font.Height = -11
        Header.Font.Name = 'Tahoma'
        Header.Font.Style = []
        Header.Height = 24
        Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoVisible]
        Images = ResourcesForm.Images16x16
        TabOrder = 1
        TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoTristateTracking]
        TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
        TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toGhostedIfUnfocused, toFullVertGridLines, toUseExplorerTheme]
        TreeOptions.SelectionOptions = [toExtendedFocus, toFullRowSelect, toMultiSelect, toRightClickSelect]
        OnDrawText = FilesystemListDrawText
        OnFreeNode = FilesystemListFreeNode
        OnGetText = FilesystemListGetText
        OnGetNodeDataSize = FilesystemListGetNodeDataSize
        ExplicitWidth = 598
        ExplicitHeight = 114
        Columns = <
          item
            MinWidth = 200
            Position = 0
            Width = 200
            WideText = 'Name'
          end
          item
            Position = 1
            Width = 273
            WideText = 'Path'
          end>
      end
    end
    object Footer: TSpTBXPanel
      AlignWithMargins = True
      Left = 5
      Top = 414
      Width = 501
      Height = 33
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alBottom
      UseDockManager = True
      TabOrder = 1
      Borders = False
      ExplicitTop = 424
      ExplicitWidth = 411
      object ButtonOk: TSpTBXButton
        AlignWithMargins = True
        Left = 264
        Top = 3
        Width = 114
        Height = 27
        Action = Ok
        Align = alRight
        TabOrder = 0
        Images = ResourcesForm.Images16x16
        ImageIndex = 1118
        ExplicitLeft = 375
      end
      object ButtonCancel: TSpTBXButton
        AlignWithMargins = True
        Left = 384
        Top = 3
        Width = 114
        Height = 27
        Action = Cancel
        Align = alRight
        TabOrder = 1
        Images = ResourcesForm.Images16x16
        ImageIndex = 143
        ExplicitLeft = 495
      end
    end
  end
  object Actions: TActionList
    Images = ResourcesForm.Images16x16
    Left = 56
    Top = 64
    object Add: TAction
      Caption = 'Add'
      ImageIndex = 179
      OnExecute = AddExecute
    end
    object Import: TAction
      Caption = 'Import'
      ImageIndex = 61
      OnExecute = ImportExecute
    end
    object Update: TAction
      Caption = 'Update'
      ImageIndex = 94
      OnExecute = UpdateExecute
    end
    object Remove: TAction
      Caption = 'Remove'
      ImageIndex = 471
      OnExecute = RemoveExecute
    end
    object Edit: TAction
      Caption = 'Edit'
      ImageIndex = 51
      OnExecute = EditExecute
    end
    object Cancel: TAction
      Caption = 'Cancel'
      ImageIndex = 143
      OnExecute = CancelExecute
    end
    object Ok: TAction
      Caption = 'Ok'
      ImageIndex = 1118
      OnExecute = OkExecute
    end
  end
  object FormStorage: TJvFormStorage
    AppStorage = RFAViewForm.AppStorage
    AppStoragePath = 'Filesystems\'
    Options = []
    BeforeSavePlacement = FormStorageBeforeSavePlacement
    AfterRestorePlacement = FormStorageAfterRestorePlacement
    StoredValues = <>
    Left = 24
    Top = 64
  end
  object Database: TSqlitePassDatabase
    DatabaseType = dbtUnknown
    DatatypeOptions.BooleanStorage = asInteger
    DatatypeOptions.DateFormat = 'YYYY-MM-DD'
    DatatypeOptions.DateStorage = asInteger
    DatatypeOptions.DateTimeFormat = 'YYYY-MM-DD hh:mm:ss.zzz'
    DatatypeOptions.DateTimeStorage = dtsDateTime
    DatatypeOptions.DecimalSeparator = ','
    DatatypeOptions.DefaultFieldType = ftUnknown
    DatatypeOptions.DetectionMode = dmTypeName
    DatatypeOptions.LoadOptions = [loDefaultProperties, loCustomProperties, loTranslationRules, loCustomFieldDefs]
    DatatypeOptions.SaveOptions = [soCustomProperties, soTranslationRules, soCustomFieldDefs]
    DatatypeOptions.UnicodeEncoding = ueUTF16
    DatatypeOptions.TimeFormat = 'hh:mm:ss'
    DatatypeOptions.TimeStorage = asInteger
    DatatypeOptions.pCustomFieldDefs = ()
    DatatypeOptions.pTranslationsRules = ()
    Options.ApplyMode = [amOverwriteDatabaseFileSettings, amAutoVacuum, amCacheSize, amCaseSensitiveLike, amCountChanges, amDefaultCacheSize, amFullColumnNames, amForeignKeys, amJournalMode, amLockingMode, amRecursiveTriggers, amSecureDelete, amSynchronous, amTemporaryStorage]
    Options.AutoVacuum = avNone
    Options.CacheSize = 2000
    Options.CaseSensitiveLike = False
    Options.CountChanges = False
    Options.DefaultCacheSize = 2000
    Options.Encoding = UTF8
    Options.ForeignKeys = False
    Options.FullColumnNames = False
    Options.JournalMode = jmDelete
    Options.JournalSizeLimit = -1
    Options.LockingMode = lmNormal
    Options.LogErrors = True
    Options.MaxPageCount = 2147483647
    Options.PageSize = 1024
    Options.QuoteStyle = qsDoubleQuote
    Options.RecursiveTriggers = False
    Options.SecureDelete = False
    Options.Synchronous = syncNormal
    Options.TemporaryStorage = tsDefault
    QueryTimeout = 0
    ShowSystemObjects = False
    VersionInfo.Component = '0.55'
    VersionInfo.Schema = -1
    VersionInfo.Package = '0.55'
    VersionInfo.SqliteLibraryNumber = 0
    VersionInfo.UserTag = -1
    Left = 24
    Top = 96
  end
  object Dataset: TSqlitePassDataset
    CalcDisplayedRecordsOnly = False
    Database = Database
    MasterSourceAutoActivate = True
    FilterMode = fmSQLDirect
    FilterRecordLowerLimit = 0
    FilterRecordUpperLimit = 0
    Indexed = True
    LocateSmartRefresh = False
    LookUpCache = False
    LookUpDisplayedRecordsOnly = False
    LookUpSmartRefresh = False
    Sorted = False
    RecordsCacheCapacity = 100
    DatabaseAutoActivate = True
    VersionInfo.Component = '0.55'
    VersionInfo.Package = '0.55'
    ParamCheck = False
    WriteMode = wmDirect
    Left = 56
    Top = 96
    pParams = ()
  end
  object DataSource: TDataSource
    DataSet = Dataset
    Left = 88
    Top = 96
  end
end

unit GuiBrowseExtract;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GuiBrowse, ActnList, JvComponentBase, JvFormPlacement, JvBaseDlg,
  JvBrowseFolder, SpTBXControls, SpTBXItem, ExtCtrls, StdCtrls, SpTBXEditors;

type
  TBrowseExtractForm = class(TBrowseForm)
    RecreateFullPath: TSpTBXCheckBox;
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  BrowseExtractForm: TBrowseExtractForm;

implementation

{$R *.dfm}

end.

unit GuiRFACommon;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, VirtualTrees;

type
  TRFACommonForm = class(TForm)
    RFAList: TVirtualStringTree;
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  RFACommonForm: TRFACommonForm;

implementation

{$R *.dfm}

end.

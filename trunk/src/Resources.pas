unit Resources;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, PngImageList;

type
  TResourcesForm = class(TForm)
    Images16x16: TPngImageList;
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  ResourcesForm: TResourcesForm;

implementation

{$R *.dfm}

end.

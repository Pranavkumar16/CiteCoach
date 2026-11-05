import {test} from 'node:test';
import assert from 'node:assert/strict';
import {strToU8,zipSync} from 'fflate';
import {officeDocument,plainDocument,textPages} from '../src/services/documentFormats';
const zip=(files:Record<string,string>)=>zipSync(Object.fromEntries(Object.entries(files).map(([name,text])=>[name,strToU8(text)])));
test('Word joins styled text runs without breaking words',()=>{
  const data=zip({'word/document.xml':'<w:document><w:body><w:p><w:r><w:t>Super</w:t></w:r><w:r><w:t>vised learning</w:t></w:r></w:p><w:p><w:r><w:t>Uses </w:t></w:r><w:r><w:t>labels.</w:t></w:r></w:p></w:body></w:document>'});
  assert.equal(officeDocument(data,'docx')[0].text,'Supervised learning\nUses labels.');
});
test('PowerPoint keeps numerical slide order and source labels',()=>{
  const result=officeDocument(zip({'ppt/slides/slide10.xml':'<a:t>Tenth slide</a:t>','ppt/slides/slide2.xml':'<a:t>Second slide</a:t>'}),'pptx');
  assert.deepEqual(result.map(p=>p.label),['Slide 2','Slide 10']);
});
test('Excel resolves sheet names, shared text and numeric cell values',()=>{
  const result=officeDocument(zip({
    'xl/workbook.xml':'<workbook><sheets><sheet name="Sales &amp; Costs" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':'<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
    'xl/sharedStrings.xml':'<sst><si><t>Revenue</t></si></sst>',
    'xl/worksheets/sheet1.xml':'<worksheet><sheetData><row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1"><v>120</v></c></row></sheetData></worksheet>'
  }),'xlsx');
  assert.equal(result[0].label,'Sales & Costs');assert.equal(result[0].text,'A1: Revenue | B1: 120');
});
test('HTML drops scripts and source sections preserve long text',()=>{
  assert.equal(plainDocument('<p>Training &amp; testing</p><script>secret()</script>','html')[0].text,'Training & testing');
  const text='learning '.repeat(1400);assert.equal(textPages(text).map(page=>page.text).join(' ').replace(/\s+/g,' ').trim(),text.trim());
});
test('malformed Office files fail instead of returning invented content',()=>assert.throws(()=>officeDocument(strToU8('not a zip'),'docx')));

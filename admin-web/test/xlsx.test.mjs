import test from 'node:test';
import assert from 'node:assert/strict';
import {buildXlsx} from '../dist/xlsx-export.mjs';
function unpack(bytes){const result={},v=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);let p=0;while(v.getUint32(p,true)===0x04034b50){const size=v.getUint32(p+18,true),n=v.getUint16(p+26,true),extra=v.getUint16(p+28,true);const name=new TextDecoder().decode(bytes.slice(p+30,p+30+n));result[name]=new TextDecoder().decode(bytes.slice(p+30+n+extra,p+30+n+extra+size));p+=30+n+extra+size;}assert.equal(v.getUint32(p,true),0x02014b50);return result;}
test('real XLSX contains OOXML package, Vietnamese strings, numeric cells and all rows',()=>{
  const files=unpack(buildXlsx({name:'Món Việt',headers:['STT','Món','kcal'],rows:Array.from({length:67},(_,i)=>[i+1,'Cơm tấm & "bò"',i])}));
  assert.equal(Object.keys(files).length,6);
  const sheet=files['xl/worksheets/sheet1.xml'];assert.match(sheet,/r="A68"/);assert.match(sheet,/Cơm tấm &amp; &quot;bò&quot;/);assert.match(sheet,/<v>0<\/v>/);assert.match(sheet,/autoFilter ref="A1:C68"/);
  assert.match(files['xl/workbook.xml'],/name="Món Việt"/);
});
test('exported user input is text, never formulas, external links or invalid XML controls',()=>{
  const files=unpack(buildXlsx({name:'A/[B]*',headers:['Text','Unknown','Zero'],rows:[['=HYPERLINK("https://evil")\u0001',null,0],['+cmd',undefined,1]]}));
  const sheet=files['xl/worksheets/sheet1.xml'];assert.match(sheet,/t="inlineStr"/);assert.match(sheet,/=HYPERLINK/);assert.ok(!sheet.includes('<f>'));assert.ok(!sheet.includes('\u0001'));assert.ok(!sheet.includes('externalLink'));
  assert.match(sheet,/<c r="B2"\/>/);assert.match(sheet,/<c r="C2"><v>0<\/v><\/c>/);
});
test('oversized or nonfinite export fails rather than truncating',()=>{
  assert.throws(()=>buildXlsx({headers:['A'],rows:[[Infinity]]}));
  assert.throws(()=>buildXlsx({headers:['A'],rows:Array(5001).fill(['a'])}));
  assert.throws(()=>buildXlsx({headers:['A'],rows:[['x'.repeat(32768)]]}));
});

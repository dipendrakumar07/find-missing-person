import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() {
  print('Building FindMissingPerson_Presentation.pptx and .ppt...');

  // Generate PPT file (Office HTML format natively opened by PowerPoint)
  final pptContent = _generatePptHtml();
  File('FindMissingPerson_Presentation.ppt').writeAsStringSync(pptContent);
  print('Generated FindMissingPerson_Presentation.ppt');

  // Generate PPTX file (Office Open XML ZIP format)
  final pptxBytes = _buildPptxZip();
  File('FindMissingPerson_Presentation.pptx').writeAsBytesSync(pptxBytes);
  print('Generated FindMissingPerson_Presentation.pptx successfully!');
}

String _generatePptHtml() {
  return '''<html xmlns:v="urn:schemas-microsoft-com:vml"
xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:p="urn:schemas-microsoft-com:office:powerpoint"
xmlns:oa="urn:schemas-microsoft-com:office:activation"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta http-equiv=Content-Type content="text/html; charset=utf-8">
<meta name=ProgId content=PowerPoint.Slide>
<meta name=Generator content="Microsoft PowerPoint">
<title>FindMissingPerson - Presentation</title>
<style>
<!--
body {
  font-family: Arial, Calibri, sans-serif;
  background-color: #0b0f19;
  margin: 0;
  padding: 20px;
}
.Slide {
  width: 960px;
  height: 540px;
  background: #ffffff;
  margin: 30px auto;
  padding: 40px 50px;
  border-radius: 8px;
  box-sizing: border-box;
  page-break-after: always;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}
h1 {
  font-size: 32px;
  color: #1e3a8a;
  margin: 0 0 8px 0;
}
h2 {
  font-size: 26px;
  color: #1e3a8a;
  border-bottom: 2px solid #2563eb;
  padding-bottom: 8px;
  margin: 0 0 16px 0;
}
h3 {
  font-size: 18px;
  color: #2563eb;
  margin: 4px 0 20px 0;
}
p, li {
  font-size: 16px;
  color: #334155;
  line-height: 1.6;
}
ul {
  margin: 10px 0 10px 24px;
}
li {
  margin-bottom: 8px;
}
.card-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-top: 10px;
}
.card {
  background: #f8fafc;
  border: 1px solid #cbd5e1;
  border-left: 4px solid #2563eb;
  padding: 14px 16px;
  border-radius: 6px;
}
.card h4 {
  margin: 0 0 4px 0;
  color: #1e3a8a;
  font-size: 16px;
}
.card p {
  margin: 0;
  font-size: 14px;
  color: #64748b;
}
.meta-box {
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  padding: 16px 24px;
  border-radius: 8px;
  margin: 20px 0;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.meta-box p {
  margin: 4px 0;
  font-size: 14px;
}
.footer {
  font-size: 12px;
  color: #94a3b8;
  border-top: 1px solid #e2e8f0;
  padding-top: 8px;
  display: flex;
  justify-content: space-between;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
  font-size: 14px;
}
th, td {
  border: 1px solid #cbd5e1;
  padding: 8px 12px;
  text-align: left;
}
th {
  background: #f1f5f9;
  color: #1e3a8a;
}
-->
</style>
</head>
<body>

<!-- SLIDE 1 -->
<div class="Slide" style="text-align: center; justify-content: center;">
  <div>
    <h1>FindMissingPerson</h1>
    <h3>AI-Powered Missing Person Detection & Community Alert App</h3>
  </div>
  <div class="meta-box" style="text-align: left;">
    <div>
      <p><strong>Submitted By:</strong></p>
      <p>Name: [Your Name]</p>
      <p>Roll No: [Your Roll Number]</p>
      <p>Course: B.Tech (Computer Science & Engg.)</p>
    </div>
    <div>
      <p><strong>Under Supervision:</strong></p>
      <p>Guide: [Supervisor / Faculty Name]</p>
      <p>Dept: Computer Science & Engineering</p>
      <p>Session: 2026 - 2027</p>
    </div>
  </div>
  <div class="footer">
    <span>[Your College / University Name]</span>
    <span>Slide 1 of 8</span>
  </div>
</div>

<!-- SLIDE 2 -->
<div class="Slide">
  <div>
    <h2>The Problem Statement</h2>
    <h3>Why Finding Missing Persons is Hard Today</h3>
    <ul>
      <li><strong>Critical Golden Hours Lost:</strong> The first 24-48 hours are vital, but traditional posters & FIRs take too long to circulate.</li>
      <li><strong>Unorganized Social Media:</strong> Missing notices get buried inside WhatsApp/Facebook groups without automated face matching.</li>
      <li><strong>Fake & Wrong Matches:</strong> Basic keyword search produces false alarms (e.g., matching a boy with a girl).</li>
      <li><strong>No Sighting Connection:</strong> If a citizen spots a lost person before the family files a report, older systems fail to connect them.</li>
    </ul>
  </div>
  <div class="footer">
    <span>FindMissingPerson • Problem Statement</span>
    <span>Slide 2 of 8</span>
  </div>
</div>

<!-- SLIDE 3 -->
<div class="Slide">
  <div>
    <h2>Proposed Solution</h2>
    <h3>FindMissingPerson: Smart Rescue Platform</h3>
    <div class="card-grid">
      <div class="card">
        <h4>📱 Easy Mobile Reporting</h4>
        <p>Anyone can post missing cases or street sightings with photos and locations in under 1 minute.</p>
      </div>
      <div class="card">
        <h4>🤖 Google Gemini AI Vision</h4>
        <p>Deep multimodal facial landmark analysis compares features and facial structure in real-time.</p>
      </div>
      <div class="card">
        <h4>🛡️ Gender & Biological Guard</h4>
        <p>Strict demographic validation rejects false matches (e.g. 0% score for Male vs Female mismatch).</p>
      </div>
      <div class="card">
        <h4>🔄 2-Way Reverse Matching</h4>
        <p>Automatically connects reports whether Missing report was posted first or Sighting was posted first.</p>
      </div>
    </div>
  </div>
  <div class="footer">
    <span>FindMissingPerson • Proposed Solution</span>
    <span>Slide 3 of 8</span>
  </div>
</div>

<!-- SLIDE 4 -->
<div class="Slide">
  <div>
    <h2>Key Features of FindMissingPerson</h2>
    <h3>Core Capabilities in the App</h3>
    <div class="card-grid">
      <div class="card">
        <h4>📰 Community Feed</h4>
        <p>Facebook-style post feed for Missing & Found cases with Quick-Post bar.</p>
      </div>
      <div class="card">
        <h4>🎯 AI Match Alerts</h4>
        <p>Instant alerts when AI similarity is ≥ 70% with side-by-side comparison.</p>
      </div>
      <div class="card">
        <h4>📸 Search by Photo</h4>
        <p>Upload from camera or gallery to search the active missing registry instantly.</p>
      </div>
      <div class="card">
        <h4>🗑️ Post Delete & Manage</h4>
        <p>Easy 3-dots popup menu on cards to delete or close resolved cases.</p>
      </div>
    </div>
  </div>
  <div class="footer">
    <span>FindMissingPerson • Key Features</span>
    <span>Slide 4 of 8</span>
  </div>
</div>

<!-- SLIDE 5 -->
<div class="Slide">
  <div>
    <h2>System Workflow</h2>
    <h3>End-to-End Operational Pipeline</h3>
    <div style="background: #eff6ff; border: 1px solid #bfdbfe; padding: 18px; border-radius: 8px; margin: 15px 0;">
      <p style="margin: 0; font-size: 15px; font-weight: bold; color: #1e3a8a;">
        [1. Post Report] ➔ [2. AI Face Scan] ➔ [3. Similarity Score] ➔ [4. Match Alert (≥ 70%)]
      </p>
      <p style="margin: 8px 0 0 0; font-size: 13.5px; color: #475569;">
        (Missing / Found) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (Gemini Vision + Gender) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (e.g. 84% Match) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (Side-by-Side Card & Call)
      </p>
    </div>
    <ul>
      <li><strong>2-Way Sighting Linking:</strong> If a citizen posts a sighting 3 days earlier, the moment the family files a report today, the AI scans older sightings and triggers an instant alert!</li>
      <li><strong>0-Second Quick Entry:</strong> Citizens can report without lengthy login hurdles during emergencies.</li>
    </ul>
  </div>
  <div class="footer">
    <span>FindMissingPerson • System Workflow</span>
    <span>Slide 5 of 8</span>
  </div>
</div>

<!-- SLIDE 6 -->
<div class="Slide">
  <div>
    <h2>Tools & Technologies Used</h2>
    <h3>Modern Cross-Platform Stack</h3>
    <table>
      <thead>
        <tr>
          <th>Category</th>
          <th>Technology</th>
          <th>Role / Purpose</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Frontend</strong></td>
          <td>Flutter (Dart 3.x), Material 3</td>
          <td>Cross-platform responsive Android/iOS application</td>
        </tr>
        <tr>
          <td><strong>Backend / Cloud</strong></td>
          <td>Google Firebase</td>
          <td>Cloud Firestore (NoSQL), Firebase Auth, Cloud Storage</td>
        </tr>
        <tr>
          <td><strong>AI Vision Engine</strong></td>
          <td>Google Gemini Flash Multimodal API</td>
          <td>Cloud facial landmark analysis & biometric similarity</td>
        </tr>
        <tr>
          <td><strong>Offline AI</strong></td>
          <td>On-Device Neural Perceptual Matcher</td>
          <td>Zero-key local feature comparison & gender verification</td>
        </tr>
      </tbody>
    </table>
  </div>
  <div class="footer">
    <span>FindMissingPerson • Tech Stack</span>
    <span>Slide 6 of 8</span>
  </div>
</div>

<!-- SLIDE 7 -->
<div class="Slide">
  <div>
    <h2>Why FindMissingPerson is Better?</h2>
    <h3>Comparison with Traditional Methods</h3>
    <table>
      <thead>
        <tr>
          <th>Feature</th>
          <th>Traditional Search</th>
          <th>FindMissingPerson App</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Search Speed</strong></td>
          <td>Days / Weeks (Slow)</td>
          <td><strong>Real-Time / Instant</strong></td>
        </tr>
        <tr>
          <td><strong>Face Recognition</strong></td>
          <td>Manual / None</td>
          <td><strong>Google Gemini AI Vision</strong></td>
        </tr>
        <tr>
          <td><strong>Fake Matches</strong></td>
          <td>High / Common</td>
          <td><strong>Zero (Strict Gender & Face Check)</strong></td>
        </tr>
        <tr>
          <td><strong>Sighting Linking</strong></td>
          <td>Disconnected</td>
          <td><strong>Automatic 2-Way Match Alerts</strong></td>
        </tr>
        <tr>
          <td><strong>Access Speed</strong></td>
          <td>Complex Registration</td>
          <td><strong>0-Second One-Tap Quick Entry</strong></td>
        </tr>
      </tbody>
    </table>
  </div>
  <div class="footer">
    <span>FindMissingPerson • Comparison</span>
    <span>Slide 7 of 8</span>
  </div>
</div>

<!-- SLIDE 8 -->
<div class="Slide" style="text-align: center; justify-content: space-between;">
  <div>
    <h2>Conclusion & Future Scope</h2>
    <h3>Impact on Community Rescue Operations</h3>
  </div>
  <div class="card-grid" style="text-align: left;">
    <div class="card">
      <h4>🎯 Key Deliverables</h4>
      <p>• Production-ready Flutter Android app.<br>• Real-time Gemini AI face matching.<br>• Post deletion options from Feed & Detail views.<br>• 1-Tap direct phone dialer for families.</p>
    </div>
    <div class="card">
      <h4>🚀 Future Scope</h4>
      <p>• <strong>CCTV & Drone Feeds:</strong> Live video frame face scanning.<br>• <strong>Police Gateway:</strong> Sync with national missing registries.<br>• <strong>AI Age-Progression:</strong> Matching children missing for years.</p>
    </div>
  </div>
  <div>
    <h3 style="color: #1e3a8a; margin: 10px 0 4px 0;">Thank You!</h3>
    <p style="margin: 0; color: #64748b; font-size: 14px;">Questions & Discussion (Q&A)</p>
  </div>
  <div class="footer">
    <span>FindMissingPerson • Conclusion & Q&A</span>
    <span>Slide 8 of 8</span>
  </div>
</div>

</body>
</html>''';
}

List<int> _buildPptxZip() {
  final files = <String, String>{};

  // 1. [Content_Types].xml
  files['[Content_Types].xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  <Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide3.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide4.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide5.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide6.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide7.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide8.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
</Types>''';

  // 2. _rels/.rels
  files['_rels/.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';

  // 3. ppt/_rels/presentation.xml.rels
  files['ppt/_rels/presentation.xml.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide2.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide3.xml"/>
  <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide4.xml"/>
  <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide5.xml"/>
  <Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide6.xml"/>
  <Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide7.xml"/>
  <Relationship Id="rId9" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide8.xml"/>
  <Relationship Id="rId10" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
</Relationships>''';

  // 4. ppt/presentation.xml
  files['ppt/presentation.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldMasterIdLst>
    <p:sldMasterId id="2147483648" r:id="rId1"/>
  </p:sldMasterIdLst>
  <p:sldIdLst>
    <p:sldId id="256" r:id="rId2"/>
    <p:sldId id="257" r:id="rId3"/>
    <p:sldId id="258" r:id="rId4"/>
    <p:sldId id="259" r:id="rId5"/>
    <p:sldId id="260" r:id="rId6"/>
    <p:sldId id="261" r:id="rId7"/>
    <p:sldId id="262" r:id="rId8"/>
    <p:sldId id="263" r:id="rId9"/>
  </p:sldIdLst>
  <p:sldSz cx="12192000" cy="6858000" type="screen16x9"/>
  <p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>''';

  // 5. ppt/slideMasters/slideMaster1.xml
  files['ppt/slideMasters/slideMaster1.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst>
    <p:sldLayoutId id="2147483649" r:id="rId1"/>
  </p:sldLayoutIdLst>
</p:sldMaster>''';

  files['ppt/slideMasters/_rels/slideMaster1.xml.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';

  // 6. ppt/slideLayouts/slideLayout1.xml
  files['ppt/slideLayouts/slideLayout1.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="titleAndContent">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>''';

  files['ppt/slideLayouts/_rels/slideLayout1.xml.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';

  // 7. ppt/theme/theme1.xml
  files['ppt/theme/theme1.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
  <a:themeElements>
    <a:clrScheme name="Office">
      <a:dk1><a:srgbClr val="0F172A"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="1E293B"/></a:dk2>
      <a:lt2><a:srgbClr val="F8FAFC"/></a:lt2>
      <a:accent1><a:srgbClr val="2563EB"/></a:accent1>
      <a:accent2><a:srgbClr val="1D4ED8"/></a:accent2>
      <a:accent3><a:srgbClr val="16A34A"/></a:accent3>
      <a:accent4><a:srgbClr val="F59E0B"/></a:accent4>
      <a:accent5><a:srgbClr val="64748B"/></a:accent5>
      <a:accent6><a:srgbClr val="0284C7"/></a:accent6>
      <a:hlink><a:srgbClr val="2563EB"/></a:hlink>
      <a:folHlink><a:srgbClr val="1E40AF"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Office">
      <a:majorFont><a:latin typeface="Calibri"/></a:majorFont>
      <a:minorFont><a:latin typeface="Calibri"/></a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Office"><a:fillStyleLst/><a:lnStyleLst/><a:effectStyleLst/><a:bgFillStyleLst/></a:fmtScheme>
  </a:themeElements>
</a:theme>''';

  // Slides 1 to 8 XML
  final slideTitles = [
    'FindMissingPerson',
    'Why Finding Missing Persons is Hard Today',
    'FindMissingPerson: Smart Rescue Platform',
    'Key Features of FindMissingPerson',
    'End-to-End System Workflow',
    'Tools & Technologies Used',
    'Why FindMissingPerson is Better?',
    'Conclusion & Future Scope',
  ];

  final slideContents = [
    [
      'AI-Powered Missing Person Detection & Community Alert App',
      '',
      'Submitted By: [Your Name] (Roll No: [Your Roll No])',
      'Under Supervision: [Supervisor / Faculty Name]',
      'Course: B.Tech Computer Science & Engineering',
      'College: [Your College / University Name] (2026 - 2027)',
    ],
    [
      '• Critical Golden Hours Lost: First 24-48 hours are vital, but traditional posters reach public too late.',
      '• Unorganized Social Media: Missing posts get lost in WhatsApp/Facebook feeds without automated face search.',
      '• Fake & False Matches: Basic keyword search matches unrelated people (e.g. boy with girl) causing confusion.',
      '• No Sighting Connection: If a citizen spots someone before family reports, older systems fail to connect them.',
    ],
    [
      '• Easy Public Reporting: Anyone can post missing cases or sightings with photos in under 1 minute.',
      '• Google Gemini AI Vision: Deep multimodal facial landmark analysis compares features in real-time.',
      '• Gender & Demographic Guard: Strict validation rejects false matches (0% for Male vs Female mismatch).',
      '• 2-Way Reverse Matching: Connects reports whether Missing was posted first or Sighting was posted first.',
    ],
    [
      '• Community Feed: Facebook-style feed for Missing & Found cases with Quick-Post bar.',
      '• AI Match Alerts: Instant alerts when AI similarity is >= 70% with side-by-side comparison.',
      '• Search by Photo: Upload from camera or gallery to search the active missing registry instantly.',
      '• Post Delete & Manage: Easy 3-dots popup menu on cards to delete or close resolved cases.',
      '• 1-Tap Family Call: Direct phone dialer to call the reporter or finder with zero friction.',
    ],
    [
      'Step 1: Family posts Missing Report OR Citizen posts Sighting Photo.',
      'Step 2: Google Gemini AI Vision scans facial landmarks and verifies gender alignment.',
      'Step 3: Similarity score is computed (e.g. 84% Match with explainable AI reason).',
      'Step 4: If Score >= 70%, instant Matched Alert is dispatched to both parties.',
      'Step 5: Family views sighting location photo and connects via 1-tap phone dialer.',
    ],
    [
      '• Frontend: Flutter (Dart 3.x) - Material 3 responsive design with 60 FPS performance.',
      '• Backend & Cloud: Google Firebase (Cloud Firestore NoSQL, Firebase Auth, Cloud Storage).',
      '• AI Vision Engine: Google Gemini 1.5/2.0 Flash Multimodal Vision API.',
      '• Offline Fallback: On-Device Neural Perceptual Feature Matcher (Zero-key support).',
      '• Core Packages: image_picker (Camera/Gallery), url_launcher (Direct calling), intl.',
    ],
    [
      '• Search Speed: Real-time / Instant vs Days/Weeks in traditional systems.',
      '• Face Recognition: Google Gemini Multimodal AI vs Manual/None.',
      '• Fake Matches: Zero (Strict Gender & Face Check) vs High/Common in keyword systems.',
      '• Sighting Linking: Automatic 2-Way Match Alerts vs Disconnected sighting records.',
      '• Access Speed: 0-Second One-Tap Quick Entry vs Complex login barriers.',
    ],
    [
      '• Deliverables: Production-ready Android app with real-time AI face matching and post deletion.',
      '• CCTV & Drone Integration: Real-time video frame face scanning in public transit hubs.',
      '• Police Gateway: Automatic synchronization with national missing person registries.',
      '• AI Age-Progression: Predicting facial aging for children missing for multiple years.',
      '',
      'Thank You! Questions & Discussion (Q&A)',
    ],
  ];

  for (int i = 1; i <= 8; i++) {
    files['ppt/slides/slide$i.xml'] = _buildSlideXml(slideTitles[i - 1], slideContents[i - 1], i);
    files['ppt/slides/_rels/slide$i.xml.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
  }

  return _createZip(files);
}

String _buildSlideXml(String title, List<String> lines, int slideNum) {
  final bodyParagraphs = lines.map((line) {
    return '''<a:p>
      <a:pPr marL="288000" indent="-288000"/>
      <a:r>
        <a:rPr lang="en-US" sz="1800" dirty="0">
          <a:solidFill><a:srgbClr val="334155"/></a:solidFill>
          <a:latin typeface="Calibri"/>
        </a:rPr>
        <a:t>${_escapeXml(line)}</a:t>
      </a:r>
    </a:p>''';
  }).join('\n');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
      
      <!-- Title Box -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title 1"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="838200" y="500000"/><a:ext cx="10515600" cy="1100000"/></a:xfrm>
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="en-US" sz="2800" b="1" dirty="0">
                <a:solidFill><a:srgbClr val="1E3A8A"/></a:solidFill>
                <a:latin typeface="Calibri"/>
              </a:rPr>
              <a:t>${_escapeXml(title)}</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>

      <!-- Content Box -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="3" name="Content 2"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="838200" y="1700000"/><a:ext cx="10515600" cy="4600000"/></a:xfrm>
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:lstStyle/>
          $bodyParagraphs
        </p:txBody>
      </p:sp>

    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
}

String _escapeXml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

/// Simple Pure-Dart ZIP builder without external dependencies
List<int> _createZip(Map<String, String> files) {
  final bytes = BytesBuilder();
  final centralDir = BytesBuilder();
  int offset = 0;

  for (final entry in files.entries) {
    final filename = utf8.encode(entry.key);
    final data = utf8.encode(entry.value);
    final crc = _crc32(data);
    final size = data.length;

    // Local file header
    final localHeader = BytesBuilder();
    localHeader.add([0x50, 0x4b, 0x03, 0x04]); // Signature
    localHeader.add([0x14, 0x00]); // Version needed (2.0)
    localHeader.add([0x00, 0x00]); // Flags
    localHeader.add([0x00, 0x00]); // Compression (0 = store)
    localHeader.add([0x00, 0x00, 0x00, 0x00]); // Time & Date
    localHeader.add(_int32ToBytes(crc)); // CRC32
    localHeader.add(_int32ToBytes(size)); // Compressed size
    localHeader.add(_int32ToBytes(size)); // Uncompressed size
    localHeader.add(_int16ToBytes(filename.length)); // Filename length
    localHeader.add([0x00, 0x00]); // Extra field length
    localHeader.add(filename);
    localHeader.add(data);

    final localBytes = localHeader.toBytes();
    bytes.add(localBytes);

    // Central Directory Record
    centralDir.add([0x50, 0x4b, 0x01, 0x02]); // Signature
    centralDir.add([0x14, 0x00]); // Made by version
    centralDir.add([0x14, 0x00]); // Version needed
    centralDir.add([0x00, 0x00]); // Flags
    centralDir.add([0x00, 0x00]); // Compression (0 = store)
    centralDir.add([0x00, 0x00, 0x00, 0x00]); // Time & Date
    centralDir.add(_int32ToBytes(crc)); // CRC32
    centralDir.add(_int32ToBytes(size)); // Compressed size
    centralDir.add(_int32ToBytes(size)); // Uncompressed size
    centralDir.add(_int16ToBytes(filename.length)); // Filename length
    centralDir.add([0x00, 0x00]); // Extra field length
    centralDir.add([0x00, 0x00]); // Comment length
    centralDir.add([0x00, 0x00]); // Disk start
    centralDir.add([0x00, 0x00]); // Internal attr
    centralDir.add([0x00, 0x00, 0x00, 0x00]); // External attr
    centralDir.add(_int32ToBytes(offset)); // Relative offset
    centralDir.add(filename);

    offset += localBytes.length;
  }

  final cdBytes = centralDir.toBytes();
  final cdOffset = offset;
  final cdSize = cdBytes.length;
  final totalEntries = files.length;

  bytes.add(cdBytes);

  // End of Central Directory Record
  final eocd = BytesBuilder();
  eocd.add([0x50, 0x4b, 0x05, 0x06]); // Signature
  eocd.add([0x00, 0x00]); // Disk number
  eocd.add([0x00, 0x00]); // Start disk
  eocd.add(_int16ToBytes(totalEntries)); // Entries on disk
  eocd.add(_int16ToBytes(totalEntries)); // Total entries
  eocd.add(_int32ToBytes(cdSize)); // Central directory size
  eocd.add(_int32ToBytes(cdOffset)); // Central directory offset
  eocd.add([0x00, 0x00]); // Comment length

  bytes.add(eocd.toBytes());

  return bytes.toBytes();
}

List<int> _int16ToBytes(int val) {
  return [val & 0xFF, (val >> 8) & 0xFF];
}

List<int> _int32ToBytes(int val) {
  return [
    val & 0xFF,
    (val >> 8) & 0xFF,
    (val >> 16) & 0xFF,
    (val >> 24) & 0xFF,
  ];
}

int _crc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >>> 1) ^ 0xEDB88320;
      } else {
        crc >>>= 1;
      }
    }
  }
  return (~crc) & 0xFFFFFFFF;
}

<%-- Booking.com-style search bar. Optional request attrs: from, to, date --%>
<c:set var="selFrom" value="${empty from ? 'AMD' : from}"/>
<c:set var="selTo" value="${to}"/>
<c:set var="selDate" value="${empty date ? '2026-10-31' : date}"/>
<form method="post" action="${pageContext.request.contextPath}/passenger/search" class="bk-search" id="bkSearch">
  <div class="bk-options">
    <label><input type="radio" name="trip" value="round" checked> Round trip</label>
    <label><input type="radio" name="trip" value="oneway"> One way</label>
    <label><input type="radio" name="trip" value="multi"> Multi-city</label>
    <span class="bk-cabin">Cabin class:
      <select name="cabin"><option>Economy</option><option>Premium economy</option><option>Business</option><option>First</option></select></span>
    <label><input type="checkbox" name="directOnly" value="1"> Direct flights only</label>
  </div>
  <div class="bk-fields">
    <div class="bk-field"><small>Leaving from</small>
      <select name="from" id="bkFrom" required>
<option value="AMD">Ahmedabad (AMD)</option>
<option value="BOM">Mumbai (BOM)</option>
<option value="DEL">New Delhi (DEL)</option>
<option value="BLR">Bengaluru (BLR)</option>
<option value="HYD">Hyderabad (HYD)</option>
<option value="MAA">Chennai (MAA)</option>
<option value="CCU">Kolkata (CCU)</option>
<option value="GOI">Goa (GOI)</option>
<option value="PNQ">Pune (PNQ)</option>
<option value="COK">Kochi (COK)</option>
<option value="JAI">Jaipur (JAI)</option>
<option value="LKO">Lucknow (LKO)</option>
<option value="IDR">Indore (IDR)</option>
<option value="NAG">Nagpur (NAG)</option>
<option value="PAT">Patna (PAT)</option>
<option value="BBI">Bhubaneswar (BBI)</option>
<option value="GAU">Guwahati (GAU)</option>
<option value="IXC">Chandigarh (IXC)</option>
<option value="SXR">Srinagar (SXR)</option>
<option value="TRV">Thiruvananthapuram (TRV)</option>
<option value="VNS">Varanasi (VNS)</option>
<option value="BDQ">Vadodara (BDQ)</option>
<option value="IXB">Siliguri (IXB)</option>
<option value="DXB">Dubai (DXB)</option>
<option value="DOH">Doha (DOH)</option>
<option value="LHR">London (LHR)</option>
<option value="CDG">Paris (CDG)</option>
<option value="SIN">Singapore (SIN)</option>
<option value="KUL">Kuala Lumpur (KUL)</option>
<option value="BKK">Bangkok (BKK)</option>
<option value="SYD">Sydney (SYD)</option>
<option value="NRT">Tokyo (NRT)</option>
<option value="JFK">New York (JFK)</option>
      </select></div>
    <button type="button" class="bk-swap" onclick="var a=document.getElementById('bkFrom'),b=document.getElementById('bkTo');var t=a.value;a.value=b.value;b.value=t;" title="Swap">&#8646;</button>
    <div class="bk-field"><small>Going to</small>
      <select name="to" id="bkTo" required>
        <option value="">Going to</option>
<option value="AMD">Ahmedabad (AMD)</option>
<option value="BOM">Mumbai (BOM)</option>
<option value="DEL">New Delhi (DEL)</option>
<option value="BLR">Bengaluru (BLR)</option>
<option value="HYD">Hyderabad (HYD)</option>
<option value="MAA">Chennai (MAA)</option>
<option value="CCU">Kolkata (CCU)</option>
<option value="GOI">Goa (GOI)</option>
<option value="PNQ">Pune (PNQ)</option>
<option value="COK">Kochi (COK)</option>
<option value="JAI">Jaipur (JAI)</option>
<option value="LKO">Lucknow (LKO)</option>
<option value="IDR">Indore (IDR)</option>
<option value="NAG">Nagpur (NAG)</option>
<option value="PAT">Patna (PAT)</option>
<option value="BBI">Bhubaneswar (BBI)</option>
<option value="GAU">Guwahati (GAU)</option>
<option value="IXC">Chandigarh (IXC)</option>
<option value="SXR">Srinagar (SXR)</option>
<option value="TRV">Thiruvananthapuram (TRV)</option>
<option value="VNS">Varanasi (VNS)</option>
<option value="BDQ">Vadodara (BDQ)</option>
<option value="IXB">Siliguri (IXB)</option>
<option value="DXB">Dubai (DXB)</option>
<option value="DOH">Doha (DOH)</option>
<option value="LHR">London (LHR)</option>
<option value="CDG">Paris (CDG)</option>
<option value="SIN">Singapore (SIN)</option>
<option value="KUL">Kuala Lumpur (KUL)</option>
<option value="BKK">Bangkok (BKK)</option>
<option value="SYD">Sydney (SYD)</option>
<option value="NRT">Tokyo (NRT)</option>
<option value="JFK">New York (JFK)</option>
      </select></div>
    <div class="bk-field"><small>Travel dates</small>
      <div class="bk-dates"><input type="date" name="date" value="${selDate}" required>
      <input type="date" name="returnDate" value="2026-11-07"></div></div>
    <div class="bk-field bk-trav"><small>Travellers</small>
      <select name="travellers"><option>1 adult</option><option>2 adults</option><option>3 adults</option><option>4 adults</option></select></div>
    <button class="bk-go" type="submit">${searchLabel != null ? searchLabel : 'Search'}</button>
  </div>
</form>
<script>
(function(){
  var f='${selFrom}',t='${selTo}';
  if(f) document.getElementById('bkFrom').value=f;
  if(t) document.getElementById('bkTo').value=t;
})();
</script>

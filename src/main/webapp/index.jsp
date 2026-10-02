<%@ page contentType="text/html;charset=UTF-8" %>
<%
    Object user = session.getAttribute("user");
    if (user != null) {
        String role = ((skybook.model.UserAccount) user).getRole().name();
        String target = "/login";
        if ("PASSENGER".equals(role)) target = "/passenger/dashboard";
        else if ("AIRLINE".equals(role)) target = "/airline/dashboard";
        else if ("ADMIN".equals(role)) target = "/admin/dashboard";
        response.sendRedirect(request.getContextPath() + target);
        return;
    }
%>
<% request.setAttribute("pageTitle", "Flights"); request.setAttribute("fullPage", true); request.setAttribute("searchLabel", "Explore"); %>
<%@ include file="WEB-INF/jsp/common/header.jsp" %>

<div class="bk-band"><div class="container pb-3">
  <h1 class="text-white fw-bold">Compare and book flights with ease</h1>
  <p class="text-white fs-4 mb-4">Discover your next dream destination</p>
  <%@ include file="WEB-INF/jsp/common/searchbar.jsp" %>
</div></div>

<div class="container">
  <div class="bk-section">
    <h2>Explore by country</h2><div class="sub">Discover trending destinations, just a flight away</div>
    <div class="row g-3">
      <div class="col-6 col-md-3"><a class="bk-country img" style="background-image:url(${pageContext.request.contextPath}/images/india.svg)" href="#"><span>🇮🇳 India</span></a></div>
      <div class="col-6 col-md-3"><a class="bk-country img" style="background-image:url(${pageContext.request.contextPath}/images/australia.svg)" href="#"><span>🇦🇺 Australia</span></a></div>
      <div class="col-6 col-md-3"><a class="bk-country img" style="background-image:url(${pageContext.request.contextPath}/images/uk.svg)" href="#"><span>🇬🇧 United Kingdom</span></a></div>
      <div class="col-6 col-md-3"><a class="bk-country anywhere" href="#"><div style="font-size:3rem">🌍</div><div class="fs-4">Anywhere</div><div class="fw-normal">Explore all destinations</div></a></div>
    </div>
  </div>

  <div class="bk-section">
    <h2>Popular flights near you</h2><div class="sub">Find deals on domestic and international flights</div>
    <div class="bk-tabs"><a href="#" class="active">International</a><a href="#">Domestic</a></div>
    <div class="row g-3">
      <div class="col-6 col-md-3"><a class="bk-country img" style="height:150px;background-image:url(${pageContext.request.contextPath}/images/london.svg)" href="#"><span>London</span></a></div>
      <div class="col-6 col-md-3"><a class="bk-country img" style="height:150px;background-image:url(${pageContext.request.contextPath}/images/melbourne.svg)" href="#"><span>Melbourne</span></a></div>
      <div class="col-6 col-md-3"><a class="bk-country img" style="height:150px;background-image:url(${pageContext.request.contextPath}/images/sydney.svg)" href="#"><span>Sydney</span></a></div>
      <div class="col-6 col-md-3"><a class="bk-country img" style="height:150px;background-image:url(${pageContext.request.contextPath}/images/dubai.svg)" href="#"><span>Dubai</span></a></div>
    </div>
  </div>
</div>

<div class="bk-features"><div class="container"><div class="row g-4">
  <div class="col-md-4 bk-feature"><div class="ico">🔍</div><div><h5>Search a huge selection</h5><p>Easily compare flights, airlines and prices - all in one place</p></div></div>
  <div class="col-md-4 bk-feature"><div class="ico">💰</div><div><h5>Pay no hidden fees</h5><p>Get a clear price breakdown, every step of the way</p></div></div>
  <div class="col-md-4 bk-feature"><div class="ico">🎫</div><div><h5>Get more flexibility</h5><p>Change your travel plans with flexible ticket options</p></div></div>
</div></div></div>

<div class="container">
  <div class="bk-section">
    <h2>Top flights from India</h2><div class="sub">Explore destinations you can reach from India and start making new plans</div>
    <div class="bk-pills"><span class="active">Popular routes</span><span>Cities</span><span>Countries</span><span>Regions</span><span>Airports</span></div>
    <div class="row">
      <c:forTokens var="r" items="AMD-LHR:London,AMD-DEL:New Delhi,AMD-BOM:Mumbai,AMD-BLR:Bengaluru,AMD-DXB:Dubai,AMD-HYD:Hyderabad,AMD-MAA:Chennai,AMD-BKK:Bangkok,AMD-CCU:Kolkata" delims=",">
        <div class="col-md-4"><a class="bk-route" href="#" onclick="var t='${fn:substringBefore(fn:substringAfter(r,'-'),':')}';document.getElementById('bkTo').value=t;window.scrollTo(0,0);return false;">
          <span class="thumb" style="background-image:url(${pageContext.request.contextPath}/images/${fn:substringAfter(r,':') == 'London' ? 'london' : (fn:substringAfter(r,':') == 'Dubai' ? 'dubai' : (fn:substringAfter(r,':') == 'Bangkok' ? 'bangkok' : 'city'))}.svg)"></span>Ahmedabad &rarr; ${fn:substringAfter(r,':')}</a></div>
      </c:forTokens>
    </div>
  </div>

  <div class="bk-section">
    <h2>Frequently asked questions</h2>
    <div class="row g-3 mt-1">
      <div class="col-md-6"><div class="bk-faq">
        <details><summary>How do I find the cheapest flights on SkyBook?</summary><p class="mt-2 text-muted">Search your route and sort results by price - the cheapest option is tagged for you.</p></details>
        <details><summary>Can I book one way flight tickets?</summary><p class="mt-2 text-muted">Yes, choose "One way" in the search bar.</p></details>
        <details><summary>How far in advance can I book a flight?</summary><p class="mt-2 text-muted">You can book any flight that an airline has published.</p></details>
      </div></div>
      <div class="col-md-6"><div class="bk-faq">
        <details><summary>Do flights get cheaper closer to departure?</summary><p class="mt-2 text-muted">Not usually - booking earlier tends to give more choice.</p></details>
        <details><summary>Are meals available on every flight?</summary><p class="mt-2 text-muted">No. Each result shows whether meals are available on that flight.</p></details>
        <details><summary>Does SkyBook charge card fees?</summary><p class="mt-2 text-muted">No hidden fees - the price you see is the price you pay.</p></details>
      </div></div>
    </div>
  </div>
</div>

<%@ include file="WEB-INF/jsp/common/footer.jsp" %>

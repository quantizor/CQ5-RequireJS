<%@ page session="false" import="java.util.Iterator,
                                 java.util.Set,
                                 java.util.HashSet,
                                 org.apache.commons.lang3.StringUtils" %>

{ Your libraries, meta tags, etc. go here. }

<%!
    public static void findDeps( Node root, Node target, Set deps ) throws RepositoryException {

        if( target.hasNodes() ){

            NodeIterator targetKids = target.getNodes();

            while (targetKids.hasNext()) {

                Node kid = targetKids.nextNode();
                if (kid != null && kid.hasProperty("sling:resourceType")) {
                  String resType = kid.getProperty("sling:resourceType").getString();

	                // You only want components inside your namespace to save some cycles
	                if( resType.indexOf("your_workspace") >= 0 ){

	                    Node comp = root.getNode("apps/" + resType);
	                    if( comp.hasProperty("requireJS")){
	                        Value[] dep = comp.getProperty("requireJS").isMultiple() ? comp.getProperty("requireJS").getValues() : new Value[] {comp.getProperty("requireJS").getValue()};
	                        for (Value v : dep){
	                            deps.add(v.getString());
	                        }
	                    }
			}

                        // Also check the page node itself for any dynamically set requireJS calls
                        if(kid.hasProperty("requireJS")){
				Value[] req = kid.getProperty("requireJS").isMultiple() ? kid.getProperty("requireJS").getValues() : new Value[] {kid.getProperty("requireJS").getValue()};
                        	for (Value v : req){
	                            deps.add(v.getString());
	                        }
                        }

	                // Check out the next nested level
	                findDeps( root, kid, deps );
                }
            }
        }
    }
%>

<%
    // Iterate through top-level parsys children and build the require.js dependency list
    Set deps = new HashSet();

    // Check at the template level first to see if there is a requireJS depedency
    Session currentSession = currentNode.getSession();
    Node root = currentSession.getRootNode();

    Node templateNode = root.getNode( "apps/" + currentNode.getProperty("sling:resourceType").getString() );

    if( templateNode.hasProperty("requireJS")){

        Value[] dep = templateNode.getProperty("requireJS").isMultiple() ? templateNode.getProperty("requireJS").getValues() : new Value[] {templateNode.getProperty("requireJS").getValue()};

        for (Value v : dep){
            deps.add(v.getString());
        }
    }

    // Then recurse!
    findDeps( root, currentNode, deps );

    // Ready for the require call.
    String finalDeps = "'" + StringUtils.join(deps, "','") + "'";
%>

<script src="/etc/designs/your_site/_js/require.min.js"></script>
<script>
    require(['/etc/designs/your_site/_js/require_config.js'], function(require_config){
        require([<%= finalDeps %>]);
    });
</script>

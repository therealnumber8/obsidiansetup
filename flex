### notes
- can use newman
- use verison control for the json or create yaml from the json and save it
- understand what the data in the confimgaps are for and when/by who are they created. implemted that the CI will also change the configmap

### procedure
- get token and save it as a vraible: go to anypoint - >acess managementment - > conencted apps -> create a new one spefically for the process that ccreates apis in "api manager"

![[Pasted image 20250428144716.png]]

- create the api via the api endpoint![[Pasted image 20250428144813.png]]
- make a ptach reqeust to set the routing cuz you can only set one via the ol api 
- make api call to deploy the api
- make api called to inboud policy, and optional for outbound

McCOIL_proportional = function(dataA1, dataA2, maxCOI=25, totalrun=10000, burnin=1000, M0=15, epsilon=0.02, err_method=1, path=getwd(), output="output.txt" ){
	
	mcCoil_prop_code_location = '/McCOIL_prop_code.so'
	if(Sys.info()['sysname'] == 'Windows'){
		mcCoil_prop_code_location = '/McCOIL_prop_code.dll'
	}

	grid = read.table(paste(path, "/fitted_beta_grid_25.txt", sep=""), head=T)
	n=nrow(dataA1)
	k=ncol(dataA1)
	M0=rep(M0, n)
	P0=rep(0.5, k)
	A1=as.vector(t(dataA1))
	A2=as.vector(t(dataA2))

	if ((n>10 & k>10)){	
		dyn.load(paste(path, mcCoil_prop_code_location, sep=""))
		Kc <- .C("McCOIL_prop", as.integer(maxCOI), as.integer(totalrun), as.integer(n), as.integer(k), as.double(A1), as.double(A2), as.integer(M0), as.double(P0), as.double(grid$A), as.double(grid$B), as.double(epsilon), as.character(output), as.character(path), as.integer(err_method))
		dyn.unload(paste(path, mcCoil_prop_code_location, sep=""))

	} else { stop(paste("Sample size is too small (n=", n, ", k=", k,").", sep=""))}
		
	##summarize results
	outputMCMC2 = read.table(paste(path, "/", output, sep=""), head=F)
	meanM= as.numeric(round(apply(outputMCMC2[(burnin+1): totalrun, (1:n)+1], 2, mean)))
	meanP= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, ((1:k)+n+1)], 2, mean))
	medianM= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, (1:n)+1], 2, median))
	medianP= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, ((1:k)+n+1)], 2, median))
	M975= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, (1:n)+1], 2, function(x) quantile(x, probs= 0.975)))
	P975= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, ((1:k)+n+1)], 2, function(x) quantile(x, probs= 0.975)))
	M025= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, (1:n)+1], 2, function(x) quantile(x, probs= 0.025)))
	P025= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, ((1:k)+n+1)], 2, function(x) quantile(x, probs= 0.025)))
	sdM= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, (1:n)+1], 2, sd))
	sdP= as.numeric(apply(outputMCMC2[(burnin+1): totalrun, ((1:k)+n+1)], 2, sd))


	if (err_method==3){
		mean_e3= as.numeric(mean(outputMCMC2[(burnin+1): totalrun, (k+n+2)]))
		median_e3= as.numeric(median(outputMCMC2[(burnin+1): totalrun, (k+n+2)]))
		e3_975=  as.numeric(quantile(outputMCMC2[(burnin+1): totalrun,  (k+n+2)], probs= 0.975))
		e3_025=  as.numeric(quantile(outputMCMC2[(burnin+1): totalrun,  (k+n+2)], probs= 0.025))
		sd_e3=  as.numeric(sd(outputMCMC2[(burnin+1): totalrun, (k+n+2)]))
	}
	if ((err_method==1) | (err_method==2)) {
			output_sum= data.frame(cbind(rep(output, (n+k)), c(rep("C", n), rep("P", k)), c(rownames(dataA1), colnames(dataA1)), c(meanM, meanP), c(medianM, medianP), round(c(sdM, sdP), digits=5), c(M025, P025), c(M975, P975)))
	}
	else {
			output_sum= data.frame(cbind(rep(output, (n+k+1)), c(rep("C", n), rep("P", k), "epsilon"), c(rownames(dataA1), colnames(dataA1), "epsilon"), c(meanM, meanP, mean_e3), c(medianM, medianP, median_e3), round(c(sdM, sdP, sd_e3), digits=5), c(M025, P025,e3_025), c(M975, P975,e3_975)))
	}
	colnames(output_sum)=  c("file", "CorP","name","mean","median","sd", "quantile0.025", "quantile0.975")
	write.table(output_sum, paste(path, "/", output, "_summary.txt", sep=""), sep="\t", col.names=T, row.names=F, quote=F)

}


